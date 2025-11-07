class Invoice
  include Mongoid::Document
  include Mongoid::Timestamps
  include Searchable

  # Fields
  field :invoice_number, type: String
  field :total_amount, type: Float, default: 0.0
  field :tax_amount, type: Float, default: 0.0
  field :subtotal, type: Float, default: 0.0
  field :discount_amount, type: Float, default: 0.0
  field :status, type: String, default: 'draft'
  field :invoice_date, type: Date
  field :payment_date, type: Date
  field :due_date, type: Date
  field :terms, type: String
  field :notes, type: String

  # Associations
  belongs_to :account
  belongs_to :billing, optional: true
  has_and_belongs_to_many :orders

  # Validations
  validates :invoice_number, presence: true, uniqueness: true
  validates :status, inclusion: {
    in: %w[draft issued sent paid void cancelled],
    message: '%{value} is not a valid status'
  }
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }

  # Indexes
  index({ invoice_number: 1 }, { unique: true })
  index({ account_id: 1 })
  index({ billing_id: 1 })
  index({ status: 1 })
  index({ invoice_date: -1 })

  # Scopes
  scope :by_status, ->(status) { where(status: status) }
  scope :by_account, ->(account_id) { where(account_id: account_id) }
  scope :unpaid, -> { where(status: %w[issued sent]) }

  # Callbacks
  before_validation :generate_invoice_number, on: :create
  before_save :calculate_totals

  # Search configuration
  def self.search_index_name
    'invoices_search'
  end

  def self.searchable_fields
    %w[invoice_number status]
  end

  def self.autocomplete_fields
    {
      'invoice_number' => 'invoice_number_autocomplete'
    }
  end

  private

  def generate_invoice_number
    return if invoice_number.present?

    loop do
      self.invoice_number = "INV-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
      break unless Invoice.where(invoice_number: invoice_number).exists?
    end
  end

  def calculate_totals
    self.total_amount = subtotal + tax_amount - discount_amount
  end
end
