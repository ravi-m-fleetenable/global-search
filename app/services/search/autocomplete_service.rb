module Search
  class AutocompleteService
    attr_reader :query, :collection_type, :user, :options

    CACHE_PREFIX = 'autocomplete'.freeze
    DEFAULT_LIMIT = 10

    def initialize(query, collection_type:, user:, options: {})
      @query = query.to_s.strip
      @collection_type = collection_type
      @user = user
      @options = options
    end

    def suggest
      return empty_response if query.length < min_chars
      return empty_response unless can_access_collection?

      # Try cache first if enabled
      cached_result = fetch_from_cache
      return cached_result if cached_result

      # Perform search
      results = perform_autocomplete_search

      # Cache results
      cache_results(results) if cache_enabled?

      format_response(results)
    rescue StandardError => e
      Rails.logger.error("Autocomplete error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      empty_response
    end

    private

    def perform_autocomplete_search
      model_class = get_model_class
      return [] unless model_class

      # Build autocomplete query
      builder = MongoDB::AtlasSearchQueryBuilder.new(query, {
        index_name: model_class.search_index_name,
        enable_fuzzy: true
      })

      # Get autocomplete fields
      autocomplete_fields = model_class.autocomplete_fields
      return [] if autocomplete_fields.empty?

      # Build compound query with all autocomplete fields
      should_clauses = autocomplete_fields.map do |text_field, autocomplete_field|
        builder.autocomplete_search(autocomplete_field, fuzzy: true)
      end

      # Add role-based filters
      filters = role_filter_service.apply_filters

      # Build search query
      search_query = if should_clauses.size == 1
        should_clauses.first
      else
        builder.compound_search(should: should_clauses)
      end

      # Add filters if present
      if filters.any?
        search_query = builder.compound_search(must: [search_query], filter: filters)
      end

      # Build pipeline
      pipeline = [
        {
          '$search' => {
            'index' => model_class.search_index_name,
            **search_query
          }
        },
        {
          '$limit' => limit
        },
        {
          '$project' => build_projection(model_class)
        }
      ]

      # Execute query
      model_class.collection.aggregate(pipeline).to_a
    end

    def build_projection(model_class)
      projection = {
        '_id' => 1,
        'score' => { '$meta' => 'searchScore' }
      }

      # Add searchable fields
      model_class.searchable_fields.each do |field|
        projection[field] = 1
      end

      # Add autocomplete text fields
      model_class.autocomplete_fields.keys.each do |field|
        projection[field] = 1
      end

      projection
    end

    def format_response(results)
      suggestions = results.map do |result|
        {
          text: extract_suggestion_text(result),
          type: extract_field_type(result),
          collection: collection_type,
          score: result['score'] || 0,
          metadata: extract_metadata(result)
        }
      end

      {
        success: true,
        query: query,
        suggestions: suggestions,
        count: suggestions.size,
        query_time_ms: 0 # Could add timing if needed
      }
    end

    def extract_suggestion_text(result)
      model_class = get_model_class
      primary_field = model_class.autocomplete_fields.keys.first
      result[primary_field].to_s
    end

    def extract_field_type(result)
      model_class = get_model_class
      model_class.autocomplete_fields.keys.first
    end

    def extract_metadata(result)
      {
        id: result['_id'].to_s,
        score: result['score']
      }
    end

    def empty_response
      {
        success: true,
        query: query,
        suggestions: [],
        count: 0,
        query_time_ms: 0
      }
    end

    def get_model_class
      case collection_type
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

    def can_access_collection?
      user.can_search_collection?(collection_type)
    end

    def role_filter_service
      @role_filter_service ||= RoleBasedFilterService.new(user, collection_type)
    end

    def min_chars
      options.fetch(:min_chars, MongoDBAtlasSearch.configuration.autocomplete_min_chars)
    end

    def limit
      options.fetch(:limit, DEFAULT_LIMIT)
    end

    def cache_enabled?
      MongoDBAtlasSearch.configuration.enable_cache && Rails.cache
    end

    def cache_key
      "#{CACHE_PREFIX}:#{collection_type}:#{user.role}:#{Digest::MD5.hexdigest(query)}"
    end

    def fetch_from_cache
      return nil unless cache_enabled?

      Rails.cache.read(cache_key)
    end

    def cache_results(results)
      return unless cache_enabled?

      formatted = format_response(results)
      ttl = MongoDBAtlasSearch.configuration.cache_ttl

      Rails.cache.write(cache_key, formatted, expires_in: ttl.seconds)
    end
  end
end
