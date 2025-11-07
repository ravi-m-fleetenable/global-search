class Billing
  include Mongoid::Document
  include Mongoid::Timestamps
  include Searchable

  # Fields
  field :billing_number, type: String
  field :amount, type: Float, default: 0.0
  field :tax_amount, type: Float, default: 0.0
  field :total_amount, type: Float, default: 0.0
  field :status, type: String, default: 'draft'
  field :billing_date, type: Date
  field :due_date, type: Date
  field :payment_date, type: Date
  field :notes, type: String

  # Associations
  belongs_to :account
  has_and_belongs_to_many :orders

  # Validations
  validates :billing_number, presence: true, uniqueness: true
  validates :status, inclusion: {
    in: %w[draft sent paid overdue cancelled],
    message: '%{value} is not a valid status'
  }
  validates :amount, numericality: { greater_than_or_equal_to: 0 }

  # Indexes
  index({ billing_number: 1 }, { unique: true })
  index({ account_id: 1 })
  index({ status: 1 })
  index({ billing_date: -1 })
  index({ due_date: 1 })

  # Scopes
  scope :by_status, ->(status) { where(status: status) }
  scope :by_account, ->(account_id) { where(account_id: account_id) }
  scope :overdue, -> { where(status: 'sent').where(:due_date.lt => Date.current) }

  # Callbacks
  before_validation :generate_billing_number, on: :create
  before_save :calculate_total

  # Search configuration
  def self.search_index_name
    'billings_search'
  end

  def self.searchable_fields
    %w[billing_number status]
  end

  def self.autocomplete_fields
    {
      'billing_number' => 'billing_number_autocomplete'
    }
  end

  private

  def generate_billing_number
    return if billing_number.present?

    loop do
      self.billing_number = "BILL-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
      break unless Billing.where(billing_number: billing_number).exists?
    end
  end

  def calculate_total
    self.total_amount = amount + tax_amount
  end
end
