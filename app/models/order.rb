class Order
  include Mongoid::Document
  include Mongoid::Timestamps
  include Searchable

  # Fields
  field :order_number, type: String
  field :hawb_numbers, type: Array, default: []
  field :status, type: String, default: 'pending'
  field :origin, type: Hash
  field :destination, type: Hash
  field :pickup_date, type: DateTime
  field :delivery_date, type: DateTime
  field :estimated_delivery, type: DateTime
  field :notes, type: String
  field :total_weight, type: Float
  field :total_value, type: Float

  # Associations
  belongs_to :account
  belongs_to :driver, optional: true
  belongs_to :fleet, optional: true
  belongs_to :assigned_dispatcher, class_name: 'User', optional: true
  has_many :pods, dependent: :destroy
  has_many :billings

  # Validations
  validates :order_number, presence: true, uniqueness: true
  validates :status, inclusion: {
    in: %w[pending confirmed in_transit delivered cancelled on_hold],
    message: '%{value} is not a valid status'
  }

  # Indexes
  index({ order_number: 1 }, { unique: true })
  index({ hawb_numbers: 1 })
  index({ status: 1 })
  index({ account_id: 1 })
  index({ driver_id: 1 })
  index({ assigned_dispatcher_id: 1 })
  index({ created_at: -1 })

  # Scopes
  scope :by_status, ->(status) { where(status: status) }
  scope :by_driver, ->(driver_id) { where(driver_id: driver_id) }
  scope :by_account, ->(account_id) { where(account_id: account_id) }
  scope :pending, -> { where(status: 'pending') }
  scope :in_transit, -> { where(status: 'in_transit') }

  # Callbacks
  before_validation :generate_order_number, on: :create

  # Search configuration
  def self.search_index_name
    'orders_search'
  end

  def self.searchable_fields
    %w[order_number hawb_numbers status]
  end

  def self.autocomplete_fields
    {
      'order_number' => 'order_number_autocomplete',
      'hawb_numbers' => 'hawb_numbers_autocomplete'
    }
  end

  private

  def generate_order_number
    return if order_number.present?

    loop do
      self.order_number = "ORD-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
      break unless Order.where(order_number: order_number).exists?
    end
  end
end
