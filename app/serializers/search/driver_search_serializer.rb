module Search
  class DriverSearchSerializer < ActiveModel::Serializer
    attributes :id, :driver_id, :full_name, :email, :phone, :license_number,
               :license_state, :license_expiry, :status,
               :search_score, :search_highlights

    belongs_to :assigned_fleet, serializer: FleetSummarySerializer, if: -> { object.assigned_fleet.present? }

    def id
      object.id.to_s
    end

    def search_score
      object.search_score || 0
    end

    def search_highlights
      object.search_highlights || {}
    end
  end

  class FleetSummarySerializer < ActiveModel::Serializer
    attributes :id, :vehicle_name, :vin, :license_plate

    def id
      object.id.to_s
    end
  end
end
