class Fleet
  include Mongoid::Document
  include Mongoid::Timestamps
  include Searchable

  # Fields
  field :vehicle_name, type: String
  field :vehicle_type, type: String
  field :vin, type: String
  field :license_plate, type: String
  field :make, type: String
  field :model, type: String
  field :year, type: Integer
  field :color, type: String
  field :capacity_weight, type: Float
  field :capacity_volume, type: Float
  field :fuel_type, type: String
  field :status, type: String, default: 'active'
  field :purchase_date, type: Date
  field :insurance_expiry, type: Date
  field :last_maintenance, type: Date
  field :next_maintenance, type: Date
  field :odometer, type: Float, default: 0.0

  # Associations
  belongs_to :current_driver, class_name: 'Driver', optional: true
  has_many :orders, dependent: :nullify

  # Validations
  validates :vin, presence: true, uniqueness: true, length: { is: 17 }
  validates :license_plate, presence: true, uniqueness: true
  validates :vehicle_type, inclusion: {
    in: %w[truck van trailer box_truck flatbed refrigerated],
    message: '%{value} is not a valid vehicle type'
  }
  validates :status, inclusion: {
    in: %w[active maintenance retired out_of_service],
    message: '%{value} is not a valid status'
  }
  validates :year, numericality: {
    greater_than_or_equal_to: 1900,
    less_than_or_equal_to: -> { Date.current.year + 1 }
  }, allow_blank: true

  # Indexes
  index({ vin: 1 }, { unique: true })
  index({ license_plate: 1 }, { unique: true })
  index({ vehicle_name: 1 })
  index({ status: 1 })
  index({ current_driver_id: 1 })
  index({ vehicle_type: 1 })

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :available, -> { active.where(current_driver_id: nil) }
  scope :by_type, ->(type) { where(vehicle_type: type) }

  # Search configuration
  def self.search_index_name
    'fleets_search'
  end

  def self.searchable_fields
    %w[vehicle_name vin license_plate make model]
  end

  def self.autocomplete_fields
    {
      'vehicle_name' => 'vehicle_name_autocomplete',
      'vin' => 'vin_autocomplete',
      'license_plate' => 'license_plate_autocomplete'
    }
  end

  # Methods
  def display_name
    vehicle_name.presence || "#{year} #{make} #{model}".strip
  end
end
