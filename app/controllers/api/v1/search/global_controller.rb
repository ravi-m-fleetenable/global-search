module Api
  module V1
    module Search
      class GlobalController < ApplicationController
        def search
          validate_search_params!

          service = ::Search::GlobalSearchService.new(
            search_params[:query],
            current_user,
            search_options
          )

          result = service.search

          render json: result, status: result[:success] ? :ok : :unprocessable_entity
        end

        private

        def validate_search_params!
          raise ActionController::ParameterMissing, 'query' if search_params[:query].blank?
        end

        def search_params
          params.permit(:query, :search_type, :page, :limit, :include_highlights, :include_facets, :include_empty, filters: [:status])
        end

        def search_options
          {
            search_type: params[:search_type] || 'all',
            page: params[:page]&.to_i || 1,
            limit: params[:limit]&.to_i || 20,
            include_highlights: params.fetch(:include_highlights, true),
            include_facets: params.fetch(:include_facets, false),
            include_empty: params.fetch(:include_empty, false),
            filters: parse_filters
          }
        end

        def parse_filters
          return {} unless params[:filters]

          filters = {}
          filters[:status] = params[:filters][:status] if params[:filters][:status]
          filters[:date_range] = parse_date_range if params[:filters][:date_range]

          filters
        end

        def parse_date_range
          return nil unless params[:filters][:date_range]

          {
            start: params[:filters][:date_range][:start],
            end: params[:filters][:date_range][:end]
          }
        end
      end
    end
  end
end
