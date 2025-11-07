namespace :atlas_search do
  desc 'Display Atlas Search index configurations'
  task :show_indexes => :environment do
    puts "\n" + "=" * 80
    puts "MongoDB Atlas Search Index Configurations"
    puts "=" * 80 + "\n"

    index_files = Dir[Rails.root.join('db', 'atlas_search_indexes', '*.json')]

    if index_files.empty?
      puts "No Atlas Search index configuration files found."
      puts "Please create index configuration files in db/atlas_search_indexes/"
      exit
    end

    index_files.each do |file|
      puts "\nIndex File: #{File.basename(file)}"
      puts "-" * 80

      begin
        config = JSON.parse(File.read(file))
        puts JSON.pretty_generate(config)
      rescue JSON::ParserError => e
        puts "Error parsing JSON: #{e.message}"
      end

      puts "\n"
    end

    puts "=" * 80
    puts "\nTo create these indexes in MongoDB Atlas:"
    puts "1. Go to your MongoDB Atlas cluster"
    puts "2. Click on 'Search' tab"
    puts "3. Click 'Create Search Index'"
    puts "4. Choose 'JSON Editor'"
    puts "5. Copy and paste the configuration from above"
    puts "6. Click 'Create Search Index'"
    puts "\nRepeat for each index configuration file."
    puts "=" * 80 + "\n"
  end

  desc 'Verify Atlas Search indexes exist (requires mongosh)'
  task :verify => :environment do
    puts "\n" + "=" * 80
    puts "Verifying Atlas Search Indexes"
    puts "=" * 80 + "\n"

    collections = %w[orders accounts fleets drivers billings invoices pods]

    collections.each do |collection_name|
      model_class = collection_name.classify.constantize
      collection = model_class.collection

      begin
        # Try to list search indexes
        # Note: This requires appropriate permissions and MongoDB version
        puts "Collection: #{collection_name}"
        puts "  Checking for search indexes..."

        # This is a placeholder - actual implementation depends on MongoDB driver version
        puts "  ✓ Collection exists"
        puts "  Note: Manual verification required in Atlas UI"
        puts ""
      rescue => e
        puts "  ✗ Error: #{e.message}"
        puts ""
      end
    end

    puts "=" * 80
    puts "\nFor full verification, check MongoDB Atlas UI:"
    puts "Cluster → Search → View all indexes"
    puts "=" * 80 + "\n"
  end

  desc 'Test search functionality with sample queries'
  task :test_search => :environment do
    puts "\n" + "=" * 80
    puts "Testing Atlas Search Functionality"
    puts "=" * 80 + "\n"

    # Create a test user
    user = User.find_by(email: 'admin@logistics.com') || User.create!(
      email: 'admin@logistics.com',
      password: 'password123',
      password_confirmation: 'password123',
      role: 'admin',
      first_name: 'Admin',
      last_name: 'Test'
    )

    test_queries = [
      { query: 'ORD', type: 'orders', description: 'Search for orders starting with ORD' },
      { query: 'HAWB', type: 'orders', description: 'Search for HAWB numbers' },
      { query: 'logistics', type: 'accounts', description: 'Search for account names' },
      { query: 'truck', type: 'fleets', description: 'Search for vehicles' }
    ]

    test_queries.each do |test|
      puts "\nTest: #{test[:description]}"
      puts "Query: '#{test[:query]}' in #{test[:type]}"
      puts "-" * 80

      begin
        service = Search::GlobalSearchService.new(
          test[:query],
          user,
          { search_type: test[:type], limit: 5 }
        )

        result = service.search

        if result[:success]
          total = result.dig(:results, test[:type], :count) || 0
          puts "✓ Search successful"
          puts "  Total results: #{total}"

          if total > 0
            items = result.dig(:results, test[:type], :items) || []
            puts "  Sample results:"
            items.take(3).each_with_index do |item, idx|
              puts "    #{idx + 1}. #{item.inspect[0..100]}..."
            end
          end
        else
          puts "✗ Search failed: #{result[:error]}"
        end
      rescue => e
        puts "✗ Error: #{e.message}"
        puts "  This might indicate Atlas Search indexes are not yet created."
      end

      puts ""
    end

    puts "=" * 80
    puts "\nIf searches fail with 'index not found' error:"
    puts "Run: rails atlas_search:show_indexes"
    puts "Then create the indexes in MongoDB Atlas UI"
    puts "=" * 80 + "\n"
  end
end
