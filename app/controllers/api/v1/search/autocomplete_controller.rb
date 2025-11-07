module Api
  module V1
    module Search
      class AutocompleteController < ApplicationController
        def suggest
          validate_autocomplete_params!

          service = ::Search::AutocompleteService.new(
            params[:q],
            collection_type: params[:type],
            user: current_user,
            options: autocomplete_options
          )

          result = service.suggest

          render json: result, status: :ok
        end

        private

        def validate_autocomplete_params!
          raise ActionController::ParameterMissing, 'q' if params[:q].blank?
          raise ActionController::ParameterMissing, 'type' if params[:type].blank?

          valid_types = %w[orders accounts fleets drivers billings invoices pods]
          unless valid_types.include?(params[:type])
            raise ActionController::ParameterMissing, "type must be one of: #{valid_types.join(', ')}"
          end
        end

        def autocomplete_options
          {
            limit: params[:limit]&.to_i || 10,
            min_chars: params[:min_chars]&.to_i || 2
          }
        end
      end
    end
  end
end
