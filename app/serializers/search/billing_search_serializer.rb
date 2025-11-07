module Search
  class BillingSearchSerializer < ActiveModel::Serializer
    attributes :id, :billing_number, :amount, :tax_amount, :total_amount,
               :status, :billing_date, :due_date, :payment_date,
               :search_score, :search_highlights

    belongs_to :account, serializer: Search::AccountSummarySerializer

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
end
