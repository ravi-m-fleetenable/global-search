class User
  include Mongoid::Document
  include Mongoid::Timestamps

  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  # Fields
  field :email, type: String
  field :encrypted_password, type: String
  field :role, type: String, default: 'driver'
  field :first_name, type: String
  field :last_name, type: String
  field :phone, type: String
  field :status, type: String, default: 'active'

  # Associations
  belongs_to :driver, optional: true

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :role, presence: true, inclusion: {
    in: %w[admin dispatcher billing driver fleet_manager],
    message: '%{value} is not a valid role'
  }
  validates :status, inclusion: { in: %w[active inactive suspended] }

  # Indexes
  index({ email: 1 }, { unique: true })
  index({ role: 1 })
  index({ driver_id: 1 })

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :by_role, ->(role) { where(role: role) }

  # Methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def admin?
    role == 'admin'
  end

  def dispatcher?
    role == 'dispatcher'
  end

  def billing?
    role == 'billing'
  end

  def driver?
    role == 'driver'
  end

  def fleet_manager?
    role == 'fleet_manager'
  end

  def can_search_collection?(collection_name)
    case role
    when 'admin'
      true
    when 'dispatcher'
      %w[orders drivers fleets pods].include?(collection_name)
    when 'billing'
      %w[billings invoices orders accounts].include?(collection_name)
    when 'driver'
      %w[orders pods drivers].include?(collection_name)
    when 'fleet_manager'
      %w[fleets drivers orders].include?(collection_name)
    else
      false
    end
  end
end
