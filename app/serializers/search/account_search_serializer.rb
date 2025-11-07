module Search
  class AccountSearchSerializer < ActiveModel::Serializer
    attributes :id, :account_name, :account_number, :company_name, :contact_person,
               :email, :phone, :account_type, :status, :credit_limit, :current_balance,
               :search_score, :search_highlights

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
