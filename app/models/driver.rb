class Driver
  include Mongoid::Document
  include Mongoid::Timestamps
  include Searchable

  # Fields
  field :driver_id, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :full_name, type: String
  field :email, type: String
  field :phone, type: String
  field :license_number, type: String
  field :license_state, type: String
  field :license_expiry, type: Date
  field :date_of_birth, type: Date
  field :hire_date, type: Date
  field :status, type: String, default: 'active'
  field :address, type: Hash
  field :emergency_contact, type: Hash

  # Associations
  belongs_to :assigned_fleet, class_name: 'Fleet', optional: true
  has_many :orders, dependent: :nullify
  has_many :pods, dependent: :restrict_with_error
  has_one :user, dependent: :nullify

  # Validations
  validates :driver_id, presence: true, uniqueness: true
  validates :first_name, :last_name, presence: true
  validates :license_number, presence: true, uniqueness: true
  validates :status, inclusion: {
    in: %w[active inactive on_leave terminated],
    message: '%{value} is not a valid status'
  }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  # Indexes
  index({ driver_id: 1 }, { unique: true })
  index({ license_number: 1 }, { unique: true })
  index({ full_name: 1 })
  index({ status: 1 })
  index({ assigned_fleet_id: 1 })

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :available, -> { active.where(assigned_fleet_id: nil) }

  # Callbacks
  before_validation :generate_driver_id, on: :create
  before_save :set_full_name

  # Search configuration
  def self.search_index_name
    'drivers_search'
  end

  def self.searchable_fields
    %w[full_name license_number]
  end

  def self.autocomplete_fields
    {
      'full_name' => 'full_name_autocomplete'
    }
  end

  private

  def generate_driver_id
    return if driver_id.present?

    loop do
      self.driver_id = "DRV-#{Time.current.year}-#{SecureRandom.hex(3).upcase}"
      break unless Driver.where(driver_id: driver_id).exists?
    end
  end

  def set_full_name
    self.full_name = "#{first_name} #{last_name}".strip
  end
end
