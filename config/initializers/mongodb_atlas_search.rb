# MongoDB Atlas Search Configuration
module MongoDBAtlasSearch
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end

  class Configuration
    attr_accessor :fuzzy_max_edits, :fuzzy_prefix_length, :fuzzy_max_expansions,
                  :autocomplete_min_chars, :autocomplete_max_results,
                  :search_timeout_ms, :enable_cache, :cache_ttl

    def initialize
      @fuzzy_max_edits = ENV.fetch('FUZZY_MAX_EDITS', 2).to_i
      @fuzzy_prefix_length = ENV.fetch('FUZZY_PREFIX_LENGTH', 0).to_i
      @fuzzy_max_expansions = ENV.fetch('FUZZY_MAX_EXPANSIONS', 50).to_i
      @autocomplete_min_chars = ENV.fetch('AUTOCOMPLETE_MIN_CHARS', 2).to_i
      @autocomplete_max_results = ENV.fetch('AUTOCOMPLETE_MAX_RESULTS', 10).to_i
      @search_timeout_ms = ENV.fetch('SEARCH_TIMEOUT_MS', 5000).to_i
      @enable_cache = ENV.fetch('ENABLE_SEARCH_CACHE', 'true') == 'true'
      @cache_ttl = ENV.fetch('SEARCH_CACHE_TTL_SECONDS', 300).to_i
    end
  end
end

# Configure defaults
MongoDBAtlasSearch.configure do |config|
  # Defaults are loaded from environment variables
end
