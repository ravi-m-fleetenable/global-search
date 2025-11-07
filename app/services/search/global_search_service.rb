module Search
  class GlobalSearchService
    attr_reader :query, :user, :options

    SEARCHABLE_COLLECTIONS = %w[orders accounts fleets drivers billings invoices pods].freeze
    DEFAULT_PAGE = 1
    DEFAULT_LIMIT = 20

    def initialize(query, user, options = {})
      @query = query.to_s.strip
      @user = user
      @options = options
    end

    def search
      start_time = Time.current

      return empty_response if query.blank?

      # Determine which collections to search
      collections_to_search = determine_collections

      # Search across all accessible collections
      results = search_collections(collections_to_search)

      # Build facets if requested
      facets = build_facets(collections_to_search) if options[:include_facets]

      # Calculate total count
      total_count = results.values.sum { |r| r[:count] }

      {
        success: true,
        query: query,
        total_results: total_count,
        search_time_ms: ((Time.current - start_time) * 1000).round(2),
        results: results,
        facets: facets || {},
        pagination: build_pagination(total_count)
      }
    rescue StandardError => e
      Rails.logger.error("Global search error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      {
        success: false,
        error: 'An error occurred during search',
        query: query,
        results: {}
      }
    end

    private

    def determine_collections
      # If specific search type is requested
      if options[:search_type] && options[:search_type] != 'all'
        return [options[:search_type]].select { |c| can_access_collection?(c) }
      end

      # Return all accessible collections
      SEARCHABLE_COLLECTIONS.select { |c| can_access_collection?(c) }
    end

    def search_collections(collections)
      results = {}

      collections.each do |collection_name|
        collection_results = search_single_collection(collection_name)
        results[collection_name] = collection_results if collection_results[:count] > 0 || options[:include_empty]
      end

      results
    end

    def search_single_collection(collection_name)
      model_class = get_model_class(collection_name)
      return empty_collection_result unless model_class

      # Build search query
      builder = MongoDB::AtlasSearchQueryBuilder.new(query, {
        index_name: model_class.search_index_name,
        enable_fuzzy: true,
        highlight_paths: model_class.searchable_fields
      })

      # Get searchable and autocomplete fields
      searchable_fields = model_class.searchable_fields
      autocomplete_fields = model_class.autocomplete_fields

      # Build search queries
      should_clauses = []

      # Add autocomplete queries (higher boost)
      autocomplete_fields.each do |text_field, autocomplete_field|
        should_clauses << {
          'autocomplete' => {
            'query' => query,
            'path' => autocomplete_field,
            'fuzzy' => builder.send(:fuzzy_options),
            'score' => { 'boost' => { 'value' => 2.0 } }
          }
        }
      end

      # Add text search queries
      searchable_fields.each do |field|
        should_clauses << {
          'text' => {
            'query' => query,
            'path' => field,
            'fuzzy' => builder.send(:fuzzy_options),
            'score' => { 'boost' => { 'value' => 1.0 } }
          }
        }
      end

      # Combine queries
      search_query = builder.compound_search(should: should_clauses)

      # Add role-based filters
      filters = RoleBasedFilterService.new(user, collection_name).apply_filters

      if filters.any?
        search_query = builder.compound_search(must: [search_query], filter: filters)
      end

      # Add status filters if specified
      if options[:filters] && options[:filters][:status]
        status_filter = builder.in_filter('status', options[:filters][:status])
        search_query = builder.compound_search(
          must: [search_query],
          filter: filters + [status_filter]
        )
      end

      # Build complete pipeline
      pipeline = [
        {
          '$search' => {
            'index' => model_class.search_index_name,
            **search_query,
            'highlight' => {
              'path' => searchable_fields
            }
          }
        },
        {
          '$facet' => {
            'results' => build_results_pipeline,
            'totalCount' => [{ '$count' => 'count' }]
          }
        }
      ]

      # Execute search
      result = model_class.collection.aggregate(pipeline).first

      # Format results
      format_collection_results(result, model_class)
    rescue StandardError => e
      Rails.logger.error("Collection search error (#{collection_name}): #{e.message}")
      empty_collection_result
    end

    def build_results_pipeline
      limit = options.fetch(:limit, DEFAULT_LIMIT)
      page = options.fetch(:page, DEFAULT_PAGE)
      skip = (page - 1) * limit

      pipeline = []
      pipeline << { '$skip' => skip } if skip > 0
      pipeline << { '$limit' => limit }
      pipeline << {
        '$addFields' => {
          'score' => { '$meta' => 'searchScore' },
          'highlights' => { '$meta' => 'searchHighlights' }
        }
      }

      pipeline
    end

    def format_collection_results(result, model_class)
      items = result['results'] || []
      total_count = result['totalCount']&.first&.dig('count') || 0

      {
        count: total_count,
        items: items.map { |item| format_item(item, model_class) }
      }
    end

    def format_item(item, model_class)
      # Instantiate the model
      instance = model_class.instantiate(item)

      # Add search metadata
      instance.search_score = item['score'] || 0
      instance.search_highlights = extract_highlights(item['highlights'])

      # Serialize using appropriate serializer
      serialize_item(instance, model_class)
    end

    def serialize_item(instance, model_class)
      serializer_class = get_serializer_class(model_class)

      if serializer_class
        serializer_class.new(instance).as_json
      else
        instance.as_document
      end
    end

    def extract_highlights(highlights_data)
      return {} unless highlights_data

      highlights = {}

      highlights_data.each do |highlight|
        path = highlight['path']
        texts = highlight['texts']&.map { |t| t['value'] }&.join(' ')
        highlights[path] = texts if texts
      end

      highlights
    end

    def build_facets(collections)
      facets = {}

      # Build collection type facet
      collection_counts = collections.map do |collection_name|
        count = count_collection_matches(collection_name)
        {
          value: collection_name,
          count: count
        }
      end

      facets[:collection_type] = collection_counts

      # Build facets for each collection
      collections.each do |collection_name|
        facet_service = FacetBuilderService.new(collection_name, user)
        collection_facets = facet_service.build_facets
        facets.merge!(collection_facets) if collection_facets.any?
      end

      facets
    end

    def count_collection_matches(collection_name)
      # This is a simplified version - you might want to cache these counts
      result = search_single_collection(collection_name)
      result[:count]
    rescue StandardError
      0
    end

    def build_pagination(total_count)
      limit = options.fetch(:limit, DEFAULT_LIMIT)
      page = options.fetch(:page, DEFAULT_PAGE)
      total_pages = (total_count.to_f / limit).ceil

      {
        current_page: page,
        total_pages: total_pages,
        limit: limit,
        total_count: total_count
      }
    end

    def can_access_collection?(collection_name)
      user.can_search_collection?(collection_name)
    end

    def get_model_class(collection_name)
      case collection_name
      when 'orders' then Order
      when 'accounts' then Account
      when 'fleets' then Fleet
      when 'drivers' then Driver
      when 'billings' then Billing
      when 'invoices' then Invoice
      when 'pods' then Pod
      else nil
      end
    end

    def get_serializer_class(model_class)
      "Search::#{model_class.name}SearchSerializer".constantize
    rescue NameError
      nil
    end

    def empty_response
      {
        success: true,
        query: query,
        total_results: 0,
        search_time_ms: 0,
        results: {},
        facets: {},
        pagination: build_pagination(0)
      }
    end

    def empty_collection_result
      {
        count: 0,
        items: []
      }
    end
  end
end
