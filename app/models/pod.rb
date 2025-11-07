class Pod
  include Mongoid::Document
  include Mongoid::Timestamps
  include Searchable

  # Fields
  field :pod_number, type: String
  field :delivery_date, type: DateTime
  field :recipient_name, type: String
  field :recipient_signature, type: String
  field :signature_url, type: String
  field :notes, type: String
  field :delivery_status, type: String, default: 'pending'
  field :location, type: Hash
  field :photo_urls, type: Array, default: []

  # Associations
  belongs_to :order
  belongs_to :driver

  # Validations
  validates :pod_number, presence: true, uniqueness: true
  validates :delivery_status, inclusion: {
    in: %w[pending completed failed damaged],
    message: '%{value} is not a valid delivery status'
  }

  # Indexes
  index({ pod_number: 1 }, { unique: true })
  index({ order_id: 1 })
  index({ driver_id: 1 })
  index({ delivery_date: -1 })

  # Scopes
  scope :by_driver, ->(driver_id) { where(driver_id: driver_id) }
  scope :by_order, ->(order_id) { where(order_id: order_id) }
  scope :completed, -> { where(delivery_status: 'completed') }

  # Callbacks
  before_validation :generate_pod_number, on: :create

  # Search configuration
  def self.search_index_name
    'pods_search'
  end

  def self.searchable_fields
    %w[pod_number]
  end

  def self.autocomplete_fields
    {
      'pod_number' => 'pod_number_autocomplete'
    }
  end

  private

  def generate_pod_number
    return if pod_number.present?

    loop do
      self.pod_number = "POD-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
      break unless Pod.where(pod_number: pod_number).exists?
    end
  end
end
