module Search
  class FacetBuilderService
    attr_reader :collection_type, :user

    def initialize(collection_type, user)
      @collection_type = collection_type
      @user = user
    end

    def build_facets
      facet_config = get_facet_configuration
      return {} if facet_config.empty?

      execute_facet_query(facet_config)
    end

    def get_facet_configuration
      case collection_type
      when 'orders'
        {
          'statusFacet' => {
            'type' => 'string',
            'path' => 'status',
            'numBuckets' => 10
          },
          'createdDateFacet' => {
            'type' => 'date',
            'path' => 'created_at',
            'boundaries' => date_boundaries,
            'default' => 'other'
          }
        }
      when 'accounts'
        {
          'accountTypeFacet' => {
            'type' => 'string',
            'path' => 'account_type',
            'numBuckets' => 10
          },
          'statusFacet' => {
            'type' => 'string',
            'path' => 'status',
            'numBuckets' => 5
          }
        }
      when 'fleets'
        {
          'vehicleTypeFacet' => {
            'type' => 'string',
            'path' => 'vehicle_type',
            'numBuckets' => 10
          },
          'statusFacet' => {
            'type' => 'string',
            'path' => 'status',
            'numBuckets' => 5
          },
          'makeFacet' => {
            'type' => 'string',
            'path' => 'make',
            'numBuckets' => 20
          }
        }
      when 'drivers'
        {
          'statusFacet' => {
            'type' => 'string',
            'path' => 'status',
            'numBuckets' => 5
          }
        }
      when 'billings'
        {
          'statusFacet' => {
            'type' => 'string',
            'path' => 'status',
            'numBuckets' => 10
          },
          'billingDateFacet' => {
            'type' => 'date',
            'path' => 'billing_date',
            'boundaries' => date_boundaries
          }
        }
      when 'invoices'
        {
          'statusFacet' => {
            'type' => 'string',
            'path' => 'status',
            'numBuckets' => 10
          },
          'invoiceDateFacet' => {
            'type' => 'date',
            'path' => 'invoice_date',
            'boundaries' => date_boundaries
          }
        }
      else
        {}
      end
    end

    def execute_facet_query(facet_config)
      model_class = get_model_class
      return {} unless model_class

      # Build empty search to get all facets
      pipeline = [
        {
          '$searchMeta' => {
            'index' => model_class.search_index_name,
            'facet' => {
              'operator' => {
                'wildcard' => {
                  'query' => '*',
                  'path' => model_class.searchable_fields.first || '_id',
                  'allowAnalyzedField' => true
                }
              },
              'facets' => facet_config
            }
          }
        }
      ]

      result = model_class.collection.aggregate(pipeline).first
      format_facets(result)
    rescue StandardError => e
      Rails.logger.error("Facet query error: #{e.message}")
      {}
    end

    private

    def format_facets(result)
      return {} unless result && result['facet']

      facets = {}

      result['facet'].each do |facet_name, facet_data|
        next unless facet_data['buckets']

        facets[facet_name.gsub('Facet', '')] = facet_data['buckets'].map do |bucket|
          {
            value: bucket['_id'],
            count: bucket['count']
          }
        end
      end

      facets
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

    def date_boundaries
      now = Time.current
      [
        now - 1.year,
        now - 6.months,
        now - 3.months,
        now - 1.month,
        now - 1.week,
        now
      ].map { |date| date.utc.iso8601 }
    end
  end
end
