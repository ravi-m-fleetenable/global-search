require 'rails_helper'

RSpec.describe Search::GlobalSearchService, type: :service do
  let(:admin_user) { create(:user, role: 'admin') }
  let(:driver_user) { create(:user, :driver) }
  let!(:account) { create(:account, account_name: 'Test Logistics Company') }
  let!(:order) { create(:order, order_number: 'ORD-TEST-001', account: account) }

  describe '#search' do
    context 'with admin user' do
      subject { described_class.new('TEST', admin_user) }

      it 'returns successful response' do
        result = subject.search
        expect(result[:success]).to be true
      end

      it 'includes search metadata' do
        result = subject.search
        expect(result).to have_key(:query)
        expect(result).to have_key(:total_results)
        expect(result).to have_key(:search_time_ms)
        expect(result).to have_key(:results)
        expect(result).to have_key(:pagination)
      end

      it 'searches across multiple collections' do
        result = subject.search
        expect(result[:results]).to be_a(Hash)
      end
    end

    context 'with driver user' do
      subject { described_class.new('TEST', driver_user) }

      it 'applies role-based filtering' do
        result = subject.search
        # Driver should only see limited collections
        expect(result[:results].keys).not_to include('accounts', 'billings', 'invoices')
      end
    end

    context 'with empty query' do
      subject { described_class.new('', admin_user) }

      it 'returns empty results' do
        result = subject.search
        expect(result[:total_results]).to eq(0)
      end
    end

    context 'with specific search type' do
      subject { described_class.new('TEST', admin_user, { search_type: 'orders' }) }

      it 'searches only specified collection' do
        result = subject.search
        expect(result[:results].keys).to eq(['orders'])
      end
    end

    context 'with pagination' do
      subject { described_class.new('TEST', admin_user, { page: 2, limit: 10 }) }

      it 'includes pagination metadata' do
        result = subject.search
        expect(result[:pagination][:current_page]).to eq(2)
        expect(result[:pagination][:limit]).to eq(10)
      end
    end
  end
end
