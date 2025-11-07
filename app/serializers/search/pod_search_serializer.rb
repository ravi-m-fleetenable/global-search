module Search
  class PodSearchSerializer < ActiveModel::Serializer
    attributes :id, :pod_number, :delivery_date, :recipient_name,
               :delivery_status, :notes,
               :search_score, :search_highlights

    belongs_to :order, serializer: OrderSummarySerializer
    belongs_to :driver, serializer: Search::DriverSummarySerializer

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

  class OrderSummarySerializer < ActiveModel::Serializer
    attributes :id, :order_number

    def id
      object.id.to_s
    end
  end
end
