# Seeds for Logistics Search System
puts "Clearing existing data..."
[User, Account, Driver, Fleet, Order, Billing, Invoice, Pod].each(&:delete_all)

puts "Creating accounts..."
accounts = []
10.times do
  accounts << Account.create!(
    account_name: Faker::Company.name,
    company_name: Faker::Company.name,
    contact_person: Faker::Name.name,
    email: Faker::Internet.email,
    phone: Faker::PhoneNumber.phone_number,
    address: {
      street: Faker::Address.street_address,
      city: Faker::Address.city,
      state: Faker::Address.state_abbr,
      zip: Faker::Address.zip_code,
      country: 'USA'
    },
    account_type: %w[shipper consignee broker freight_forwarder].sample,
    credit_limit: rand(10000..100000),
    current_balance: rand(0..50000),
    status: %w[active active active suspended].sample
  )
end
puts "Created #{accounts.count} accounts"

puts "Creating drivers..."
drivers = []
20.times do
  drivers << Driver.create!(
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    email: Faker::Internet.email,
    phone: Faker::PhoneNumber.phone_number,
    license_number: "DL#{Faker::Number.number(digits: 8)}",
    license_state: Faker::Address.state_abbr,
    license_expiry: Faker::Date.forward(days: 365),
    date_of_birth: Faker::Date.birthday(min_age: 25, max_age: 65),
    hire_date: Faker::Date.backward(days: 1000),
    status: %w[active active active inactive on_leave].sample,
    address: {
      street: Faker::Address.street_address,
      city: Faker::Address.city,
      state: Faker::Address.state_abbr,
      zip: Faker::Address.zip_code
    },
    emergency_contact: {
      name: Faker::Name.name,
      phone: Faker::PhoneNumber.phone_number,
      relationship: %w[spouse parent sibling friend].sample
    }
  )
end
puts "Created #{drivers.count} drivers"

puts "Creating fleets..."
fleets = []
15.times do
  fleet = Fleet.create!(
    vehicle_name: "#{Faker::Vehicle.make} #{Faker::Vehicle.model}",
    vehicle_type: %w[truck van trailer box_truck flatbed refrigerated].sample,
    vin: Faker::Vehicle.vin,
    license_plate: "#{Faker::Address.state_abbr}#{Faker::Number.number(digits: 6)}",
    make: Faker::Vehicle.make,
    model: Faker::Vehicle.model,
    year: rand(2015..2024),
    color: Faker::Vehicle.color,
    capacity_weight: rand(5000..40000),
    capacity_volume: rand(100..1000),
    fuel_type: %w[diesel gasoline electric hybrid].sample,
    status: %w[active active maintenance out_of_service].sample,
    purchase_date: Faker::Date.backward(days: 2000),
    insurance_expiry: Faker::Date.forward(days: 180),
    last_maintenance: Faker::Date.backward(days: 30),
    next_maintenance: Faker::Date.forward(days: 60),
    odometer: rand(10000..200000).to_f
  )

  # Assign driver to some fleets
  if fleet.status == 'active' && drivers.sample.status == 'active'
    driver = drivers.sample
    fleet.update(current_driver: driver)
    driver.update(assigned_fleet: fleet)
  end

  fleets << fleet
end
puts "Created #{fleets.count} fleets"

puts "Creating users..."
users = []

# Create admin user
users << User.create!(
  email: 'admin@logistics.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Admin',
  last_name: 'User',
  role: 'admin',
  status: 'active'
)

# Create dispatcher
users << User.create!(
  email: 'dispatcher@logistics.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'John',
  last_name: 'Dispatcher',
  role: 'dispatcher',
  status: 'active'
)

# Create billing user
users << User.create!(
  email: 'billing@logistics.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Jane',
  last_name: 'Billing',
  role: 'billing',
  status: 'active'
)

# Create driver users
3.times do |i|
  driver = drivers[i]
  users << User.create!(
    email: "driver#{i + 1}@logistics.com",
    password: 'password123',
    password_confirmation: 'password123',
    first_name: driver.first_name,
    last_name: driver.last_name,
    role: 'driver',
    status: 'active',
    driver: driver
  )
end

# Create fleet manager
users << User.create!(
  email: 'fleetmanager@logistics.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Bob',
  last_name: 'Manager',
  role: 'fleet_manager',
  status: 'active'
)
puts "Created #{users.count} users"

puts "Creating orders..."
orders = []
100.times do
  order = Order.create!(
    account: accounts.sample,
    driver: drivers.select { |d| d.status == 'active' }.sample,
    fleet: fleets.select { |f| f.status == 'active' }.sample,
    assigned_dispatcher: users.find { |u| u.role == 'dispatcher' },
    hawb_numbers: Array.new(rand(1..3)) { "HAWB-#{Faker::Number.number(digits: 10)}" },
    status: %w[pending confirmed in_transit delivered cancelled on_hold].sample,
    origin: {
      address: Faker::Address.street_address,
      city: Faker::Address.city,
      state: Faker::Address.state_abbr,
      zip: Faker::Address.zip_code,
      country: 'USA'
    },
    destination: {
      address: Faker::Address.street_address,
      city: Faker::Address.city,
      state: Faker::Address.state_abbr,
      zip: Faker::Address.zip_code,
      country: 'USA'
    },
    pickup_date: Faker::Date.backward(days: 30),
    delivery_date: Faker::Date.forward(days: 7),
    estimated_delivery: Faker::Date.forward(days: 10),
    total_weight: rand(100..10000).to_f,
    total_value: rand(1000..50000).to_f,
    notes: Faker::Lorem.sentence
  )
  orders << order
end
puts "Created #{orders.count} orders"

puts "Creating PODs..."
pods = []
orders.select { |o| o.status == 'delivered' }.each do |order|
  pods << Pod.create!(
    order: order,
    driver: order.driver,
    delivery_date: order.delivery_date || Time.current,
    recipient_name: Faker::Name.name,
    recipient_signature: 'Signed',
    signature_url: Faker::Internet.url,
    delivery_status: 'completed',
    notes: Faker::Lorem.sentence,
    location: {
      latitude: Faker::Address.latitude,
      longitude: Faker::Address.longitude
    },
    photo_urls: [Faker::Internet.url, Faker::Internet.url]
  )
end
puts "Created #{pods.count} PODs"

puts "Creating billings..."
billings = []
30.times do
  billing = Billing.create!(
    account: accounts.sample,
    amount: rand(1000..10000).to_f,
    tax_amount: rand(100..1000).to_f,
    status: %w[draft sent paid overdue cancelled].sample,
    billing_date: Faker::Date.backward(days: 60),
    due_date: Faker::Date.forward(days: 30),
    payment_date: [nil, Faker::Date.forward(days: 15)].sample,
    notes: Faker::Lorem.sentence
  )

  # Associate with some orders
  billing.orders = orders.sample(rand(1..5))
  billing.save

  billings << billing
end
puts "Created #{billings.count} billings"

puts "Creating invoices..."
invoices = []
40.times do
  invoice = Invoice.create!(
    account: accounts.sample,
    billing: billings.sample,
    subtotal: rand(1000..10000).to_f,
    tax_amount: rand(100..1000).to_f,
    discount_amount: rand(0..500).to_f,
    status: %w[draft issued sent paid void cancelled].sample,
    invoice_date: Faker::Date.backward(days: 60),
    due_date: Faker::Date.forward(days: 30),
    payment_date: [nil, Faker::Date.forward(days: 15)].sample,
    terms: 'Net 30',
    notes: Faker::Lorem.sentence
  )

  # Associate with some orders
  invoice.orders = orders.sample(rand(1..3))
  invoice.save

  invoices << invoice
end
puts "Created #{invoices.count} invoices"

puts "\n================================"
puts "Seed data created successfully!"
puts "================================"
puts "\nTest Users:"
puts "  Admin: admin@logistics.com / password123"
puts "  Dispatcher: dispatcher@logistics.com / password123"
puts "  Billing: billing@logistics.com / password123"
puts "  Driver: driver1@logistics.com / password123"
puts "  Fleet Manager: fleetmanager@logistics.com / password123"
puts "\nData Summary:"
puts "  Accounts: #{Account.count}"
puts "  Drivers: #{Driver.count}"
puts "  Fleets: #{Fleet.count}"
puts "  Orders: #{Order.count}"
puts "  PODs: #{Pod.count}"
puts "  Billings: #{Billing.count}"
puts "  Invoices: #{Invoice.count}"
puts "  Users: #{User.count}"
puts "================================\n"
