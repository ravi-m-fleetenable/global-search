module MongoDB
  class AtlasSearchQueryBuilder
    attr_reader :query_text, :options

    def initialize(query_text, options = {})
      @query_text = query_text
      @options = default_options.merge(options)
    end

    # Build text search query
    def text_search(paths, fuzzy: true)
      query = {
        'text' => {
          'query' => query_text,
          'path' => paths
        }
      }

      if fuzzy && options[:enable_fuzzy]
        query['text']['fuzzy'] = fuzzy_options
      end

      query
    end

    # Build autocomplete query
    def autocomplete_search(path, fuzzy: true)
      query = {
        'autocomplete' => {
          'query' => query_text,
          'path' => path
        }
      }

      if fuzzy && options[:enable_fuzzy]
        query['autocomplete']['fuzzy'] = fuzzy_options
      end

      query
    end

    # Build compound query (combines multiple searches)
    def compound_search(should: [], must: [], must_not: [], filter: [])
      compound = {}
      compound['should'] = should if should.any?
      compound['must'] = must if must.any?
      compound['mustNot'] = must_not if must_not.any?
      compound['filter'] = filter if filter.any?

      { 'compound' => compound }
    end

    # Build multi-field search with boosting
    def multi_field_search(field_configs)
      should_clauses = field_configs.map do |config|
        query = {
          'text' => {
            'query' => query_text,
            'path' => config[:path]
          }
        }

        # Add fuzzy if enabled
        if options[:enable_fuzzy] && config.fetch(:fuzzy, true)
          query['text']['fuzzy'] = fuzzy_options
        end

        # Add boost if specified
        if config[:boost]
          query['text']['score'] = { 'boost' => { 'value' => config[:boost] } }
        end

        query
      end

      compound_search(should: should_clauses)
    end

    # Build autocomplete with fallback to text search
    def autocomplete_with_fallback(autocomplete_path, text_path)
      should_clauses = [
        autocomplete_search(autocomplete_path, fuzzy: true),
        {
          'text' => {
            'query' => query_text,
            'path' => text_path,
            'fuzzy' => fuzzy_options,
            'score' => { 'boost' => { 'value' => 0.5 } }
          }
        }
      ]

      compound_search(should: should_clauses)
    end

    # Build facet query
    def facet_query(facet_definitions)
      {
        'index' => options[:index_name],
        'facet' => {
          'operator' => options[:facet_operator] || text_search(options[:search_paths]),
          'facets' => facet_definitions
        }
      }
    end

    # Build highlight configuration
    def highlight_config(paths)
      {
        'highlight' => {
          'path' => paths,
          'maxCharsToExamine' => options[:max_chars_to_examine] || 500000,
          'maxNumPassages' => options[:max_num_passages] || 5
        }
      }
    end

    # Build range filter
    def range_filter(path, min: nil, max: nil)
      range = {}
      range['gte'] = min if min
      range['lte'] = max if max

      {
        'range' => {
          'path' => path,
          **range
        }
      }
    end

    # Build equals filter
    def equals_filter(path, value)
      {
        'equals' => {
          'path' => path,
          'value' => value
        }
      }
    end

    # Build in filter (for arrays)
    def in_filter(path, values)
      {
        'in' => {
          'path' => path,
          'value' => values
        }
      }
    end

    # Build complete search pipeline with all features
    def build_complete_pipeline(
      search_paths:,
      autocomplete_paths: {},
      filters: [],
      facets: {},
      sort: nil,
      skip: 0,
      limit: 20,
      include_highlights: true
    )

      # Build main search query
      search_queries = []

      # Add autocomplete searches
      autocomplete_paths.each do |text_path, autocomplete_path|
        search_queries << autocomplete_with_fallback(autocomplete_path, text_path)
      end

      # Add text searches for remaining paths
      remaining_paths = search_paths - autocomplete_paths.keys
      if remaining_paths.any?
        search_queries << text_search(remaining_paths)
      end

      # Combine into compound query
      main_query = search_queries.size == 1 ? search_queries.first : compound_search(should: search_queries)

      # Add filters if present
      if filters.any?
        main_query = compound_search(must: [main_query], filter: filters)
      end

      # Build pipeline
      pipeline = []

      # Add search stage
      search_stage = {
        'index' => options[:index_name],
        **main_query
      }

      # Add highlight if enabled
      if include_highlights && options[:highlight_paths]
        search_stage.merge!(highlight_config(options[:highlight_paths]))
      end

      pipeline << { '$search' => search_stage }

      # Add facets stage if requested
      if facets.any?
        pipeline << {
          '$facet' => {
            'results' => build_results_pipeline(sort, skip, limit),
            'metadata' => build_metadata_pipeline(facets)
          }
        }
      else
        # Add sort if specified
        pipeline << { '$sort' => sort } if sort

        # Add pagination
        pipeline << { '$skip' => skip } if skip > 0
        pipeline << { '$limit' => limit }

        # Add score projection
        pipeline << {
          '$addFields' => {
            'score' => { '$meta' => 'searchScore' }
          }
        }

        # Add highlights if enabled
        if include_highlights
          pipeline << {
            '$addFields' => {
              'highlights' => { '$meta' => 'searchHighlights' }
            }
          }
        end
      end

      pipeline
    end

    private

    def default_options
      config = MongoDBAtlasSearch.configuration

      {
        enable_fuzzy: true,
        fuzzy_max_edits: config.fuzzy_max_edits,
        fuzzy_prefix_length: config.fuzzy_prefix_length,
        fuzzy_max_expansions: config.fuzzy_max_expansions
      }
    end

    def fuzzy_options
      {
        'maxEdits' => options[:fuzzy_max_edits],
        'prefixLength' => options[:fuzzy_prefix_length],
        'maxExpansions' => options[:fuzzy_max_expansions]
      }
    end

    def build_results_pipeline(sort, skip, limit)
      pipeline = []
      pipeline << { '$sort' => sort } if sort
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

    def build_metadata_pipeline(facets)
      [
        { '$count' => 'total' },
        { '$addFields' => { 'facets' => facets } }
      ]
    end
  end
end
