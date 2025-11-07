module Api
  module V1
    module Search
      class FacetsController < ApplicationController
        def index
          validate_facets_params!

          service = ::Search::FacetBuilderService.new(
            params[:collection],
            current_user
          )

          facets = service.build_facets

          render json: {
            success: true,
            collection: params[:collection],
            facets: facets
          }, status: :ok
        rescue StandardError => e
          render json: {
            success: false,
            error: e.message
          }, status: :unprocessable_entity
        end

        private

        def validate_facets_params!
          raise ActionController::ParameterMissing, 'collection' if params[:collection].blank?

          valid_collections = %w[orders accounts fleets drivers billings invoices pods]
          unless valid_collections.include?(params[:collection])
            raise ActionController::ParameterMissing, "collection must be one of: #{valid_collections.join(', ')}"
          end

          unless current_user.can_search_collection?(params[:collection])
            raise Pundit::NotAuthorizedError, 'You do not have access to this collection'
          end
        end
      end
    end
  end
end
