module Searchable
  extend ActiveSupport::Concern

  included do
    # Define searchable configuration methods that models should override
  end

  class_methods do
    # Override in models to specify the Atlas Search index name
    def search_index_name
      "#{collection_name}_search"
    end

    # Override in models to specify searchable fields
    def searchable_fields
      []
    end

    # Override in models to specify autocomplete field mappings
    def autocomplete_fields
      {}
    end

    # Perform Atlas Search query
    def atlas_search(query_pipeline)
      collection.aggregate(query_pipeline).to_a
    end

    # Build basic search pipeline
    def search_pipeline(search_query, options = {})
      pipeline = []

      # Add $search stage
      pipeline << { '$search' => search_query }

      # Add $limit if specified
      pipeline << { '$limit' => options[:limit] } if options[:limit]

      # Add $skip if specified
      pipeline << { '$skip' => options[:skip] } if options[:skip]

      # Add $project to include score
      if options[:include_score]
        pipeline << {
          '$project' => {
            '_id' => 1,
            **searchable_fields.map { |f| [f, 1] }.to_h,
            'score' => { '$meta' => 'searchScore' }
          }
        }
      end

      pipeline
    end

    # Get search metadata (for facets and counts)
    def search_meta(search_query)
      pipeline = [
        {
          '$searchMeta' => search_query
        }
      ]

      collection.aggregate(pipeline).first || {}
    end
  end

  # Instance methods
  def search_score
    @search_score ||= 0.0
  end

  def search_score=(score)
    @search_score = score
  end

  def search_highlights
    @search_highlights ||= {}
  end

  def search_highlights=(highlights)
    @search_highlights = highlights
  end
end
