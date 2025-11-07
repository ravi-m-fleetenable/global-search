module Api
  module V1
    module Search
      class AdvancedController < ApplicationController
        # Advanced search with custom query building
        def search
          validate_advanced_params!

          # Build custom search based on advanced parameters
          result = perform_advanced_search

          render json: result, status: result[:success] ? :ok : :unprocessable_entity
        end

        private

        def validate_advanced_params!
          raise ActionController::ParameterMissing, 'At least one search parameter is required' if search_criteria.empty?
        end

        def perform_advanced_search
          collection_type = params[:collection] || 'orders'

          unless current_user.can_search_collection?(collection_type)
            return {
              success: false,
              error: 'Unauthorized access to collection'
            }
          end

          model_class = get_model_class(collection_type)
          return { success: false, error: 'Invalid collection' } unless model_class

          # Build advanced search query
          builder = MongoDB::AtlasSearchQueryBuilder.new('', {
            index_name: model_class.search_index_name
          })

          # Build compound query from criteria
          must_clauses = []
          should_clauses = []

          search_criteria.each do |field, value|
            if value.is_a?(Array)
              must_clauses << builder.in_filter(field, value)
            elsif value.is_a?(Hash) && (value[:min] || value[:max])
              must_clauses << builder.range_filter(field, min: value[:min], max: value[:max])
            else
              should_clauses << builder.text_search([field], fuzzy: true)
            end
          end

          # Add role-based filters
          filters = ::Search::RoleBasedFilterService.new(current_user, collection_type).apply_filters

          # Build final query
          search_query = builder.compound_search(
            must: must_clauses,
            should: should_clauses,
            filter: filters
          )

          # Execute search
          pipeline = [
            {
              '$search' => {
                'index' => model_class.search_index_name,
                **search_query
              }
            },
            { '$limit' => params[:limit]&.to_i || 20 },
            {
              '$addFields' => {
                'score' => { '$meta' => 'searchScore' }
              }
            }
          ]

          results = model_class.collection.aggregate(pipeline).to_a

          {
            success: true,
            collection: collection_type,
            count: results.size,
            results: results
          }
        rescue StandardError => e
          Rails.logger.error("Advanced search error: #{e.message}")
          {
            success: false,
            error: e.message
          }
        end

        def search_criteria
          params.permit(:order_number, :account_name, :status, :vehicle_name, :vin).to_h.compact
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
      end
    end
  end
end
