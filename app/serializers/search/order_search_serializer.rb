module Search
  class OrderSearchSerializer < ActiveModel::Serializer
    attributes :id, :order_number, :hawb_numbers, :status, :origin, :destination,
               :pickup_date, :delivery_date, :estimated_delivery, :created_at,
               :search_score, :search_highlights

    belongs_to :account, serializer: AccountSummarySerializer
    belongs_to :driver, serializer: DriverSummarySerializer, if: -> { object.driver.present? }

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

  class AccountSummarySerializer < ActiveModel::Serializer
    attributes :id, :account_name, :account_number

    def id
      object.id.to_s
    end
  end

  class DriverSummarySerializer < ActiveModel::Serializer
    attributes :id, :full_name, :driver_id

    def id
      object.id.to_s
    end
  end
end
