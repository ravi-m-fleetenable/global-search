class Account
  include Mongoid::Document
  include Mongoid::Timestamps
  include Searchable

  # Fields
  field :account_name, type: String
  field :account_number, type: String
  field :company_name, type: String
  field :contact_person, type: String
  field :email, type: String
  field :phone, type: String
  field :address, type: Hash
  field :account_type, type: String
  field :credit_limit, type: Float, default: 0.0
  field :current_balance, type: Float, default: 0.0
  field :status, type: String, default: 'active'

  # Associations
  has_many :orders, dependent: :restrict_with_error
  has_many :billings, dependent: :restrict_with_error
  has_many :invoices, dependent: :restrict_with_error

  # Validations
  validates :account_name, presence: true
  validates :account_number, presence: true, uniqueness: true
  validates :account_type, inclusion: {
    in: %w[shipper consignee broker freight_forwarder],
    message: '%{value} is not a valid account type'
  }
  validates :status, inclusion: { in: %w[active suspended closed] }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  # Indexes
  index({ account_name: 1 })
  index({ account_number: 1 }, { unique: true })
  index({ status: 1 })
  index({ account_type: 1 })
  index({ email: 1 })

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :by_type, ->(type) { where(account_type: type) }

  # Callbacks
  before_validation :generate_account_number, on: :create

  # Search configuration
  def self.search_index_name
    'accounts_search'
  end

  def self.searchable_fields
    %w[account_name company_name account_number]
  end

  def self.autocomplete_fields
    {
      'account_name' => 'account_name_autocomplete',
      'company_name' => 'company_name_autocomplete'
    }
  end

  private

  def generate_account_number
    return if account_number.present?

    loop do
      self.account_number = "ACC-#{Time.current.year}-#{SecureRandom.hex(4).upcase}"
      break unless Account.where(account_number: account_number).exists?
    end
  end
end
