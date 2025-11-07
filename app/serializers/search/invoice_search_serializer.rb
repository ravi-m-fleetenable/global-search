module Search
  class InvoiceSearchSerializer < ActiveModel::Serializer
    attributes :id, :invoice_number, :total_amount, :tax_amount, :subtotal,
               :discount_amount, :status, :invoice_date, :payment_date, :due_date,
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
