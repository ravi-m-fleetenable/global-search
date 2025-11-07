module Search
  class FleetSearchSerializer < ActiveModel::Serializer
    attributes :id, :vehicle_name, :vehicle_type, :vin, :license_plate,
               :make, :model, :year, :status, :display_name,
               :search_score, :search_highlights

    belongs_to :current_driver, serializer: DriverSummarySerializer, if: -> { object.current_driver.present? }

    def id
      object.id.to_s
    end

    def display_name
      object.display_name
    end

    def search_score
      object.search_score || 0
    end

    def search_highlights
      object.search_highlights || {}
    end
  end
end
