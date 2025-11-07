# Global Search API - Logistics & Transportation System

A comprehensive Ruby on Rails API with MongoDB Atlas Search for global search across logistics and transportation operations.

## Features

- 🔍 **Global Search**: Search across 7 collections (Orders, Accounts, Fleets, Drivers, Billings, Invoices, PODs)
- ⚡ **Fast Autocomplete**: Type-ahead suggestions with fuzzy matching
- 🎯 **Faceted Search**: Filter by status, dates, types, etc.
- 🔒 **Role-Based Access Control**: Dispatcher, Billing, Driver, Fleet Manager, Admin roles
- 💡 **Fuzzy Search**: Levenshtein distance-based typo tolerance
- 📊 **Relevance Ranking**: MongoDB Atlas Search powered ranking
- 🎨 **Highlighted Results**: Matched terms highlighted in results
- 📄 **Pagination**: Efficient result pagination

## Tech Stack

- **Framework**: Ruby on Rails 7.1
- **Database**: MongoDB Atlas M50 cluster
- **Search Engine**: MongoDB Atlas Search
- **Authentication**: Devise + JWT
- **Authorization**: Pundit
- **Caching**: Redis
- **API**: RESTful JSON API

## Prerequisites

- Ruby 3.2.2
- MongoDB Atlas M50+ cluster
- Redis (optional, for caching)
- Node.js (optional, for frontend integration)

## Installation

### 1. Clone the repository

```bash
git clone <repository-url>
cd global-search
```

### 2. Install dependencies

```bash
bundle install
```

### 3. Environment setup

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```env
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/logistics_production
JWT_SECRET_KEY=your-secret-key-here
REDIS_URL=redis://localhost:6379/0
CORS_ORIGINS=http://localhost:3000
```

### 4. Setup MongoDB Atlas Search Indexes

This is **CRITICAL** - the search will not work without these indexes!

```bash
# Display all index configurations
rails atlas_search:show_indexes
```

Then, for **each collection** (orders, accounts, fleets, drivers, billings, invoices, pods):

1. Go to [MongoDB Atlas](https://cloud.mongodb.com/)
2. Select your cluster → **Search** tab
3. Click **"Create Search Index"**
4. Choose **"JSON Editor"**
5. Select the collection (e.g., `orders`)
6. Copy the configuration from `db/atlas_search_indexes/<collection>_search.json`
7. Paste and click **"Create Search Index"**
8. Wait for index to build (usually 1-2 minutes)

Repeat for all 7 collections!

### 5. Seed the database

```bash
rails db:seed
```

This creates:
- 10 accounts
- 20 drivers
- 15 fleets
- 100 orders
- 30 billings
- 40 invoices
- PODs for delivered orders
- Test users (see below)

### 6. Start the server

```bash
rails server -p 3000
```

API available at: `http://localhost:3000`

## Test Users

After seeding, you can login with these users:

| Role | Email | Password | Access |
|------|-------|----------|--------|
| Admin | admin@logistics.com | password123 | All collections |
| Dispatcher | dispatcher@logistics.com | password123 | Orders, Drivers, Fleets, PODs |
| Billing | billing@logistics.com | password123 | Billings, Invoices, Orders, Accounts |
| Driver | driver1@logistics.com | password123 | Own orders and PODs only |
| Fleet Manager | fleetmanager@logistics.com | password123 | Fleets, Drivers, Orders |

## API Endpoints

### Authentication

#### Login
```bash
POST /api/v1/users/sign_in
Content-Type: application/json

{
  "user": {
    "email": "admin@logistics.com",
    "password": "password123"
  }
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": "...",
    "email": "admin@logistics.com",
    "role": "admin"
  }
}
```

Use the token in subsequent requests:
```bash
Authorization: Bearer <token>
```

### Global Search

#### Search Across All Collections
```bash
POST /api/v1/search/global
Authorization: Bearer <token>
Content-Type: application/json

{
  "query": "ORD-12345",
  "page": 1,
  "limit": 20,
  "include_highlights": true,
  "include_facets": false
}
```

**Response:**
```json
{
  "success": true,
  "query": "ORD-12345",
  "total_results": 1,
  "search_time_ms": 287.5,
  "results": {
    "orders": {
      "count": 1,
      "items": [
        {
          "id": "...",
          "order_number": "ORD-12345",
          "hawb_numbers": ["HAWB-98765"],
          "status": "in_transit",
          "account": {
            "id": "...",
            "account_name": "Acme Logistics"
          },
          "search_score": 8.5,
          "search_highlights": {
            "order_number": "<em>ORD-12345</em>"
          }
        }
      ]
    }
  },
  "pagination": {
    "current_page": 1,
    "total_pages": 1,
    "limit": 20,
    "total_count": 1
  }
}
```

#### Search Specific Collection
```bash
POST /api/v1/search/global
Authorization: Bearer <token>
Content-Type: application/json

{
  "query": "Toyota",
  "search_type": "fleets",
  "filters": {
    "status": ["active"]
  }
}
```

### Autocomplete

```bash
GET /api/v1/search/autocomplete?q=ord&type=orders
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "query": "ord",
  "suggestions": [
    {
      "text": "ORD-20250107-A1B2C3D4",
      "type": "order_number",
      "collection": "orders",
      "score": 9.2,
      "metadata": {
        "id": "...",
        "score": 9.2
      }
    }
  ],
  "count": 10,
  "query_time_ms": 45
}
```

### Facets

```bash
GET /api/v1/search/facets?collection=orders
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "collection": "orders",
  "facets": {
    "status": [
      {"value": "pending", "count": 15},
      {"value": "in_transit", "count": 30},
      {"value": "delivered", "count": 50}
    ]
  }
}
```

## Search Examples

### Search by Order Number
```bash
curl -X POST http://localhost:3000/api/v1/search/global \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"query": "ORD-12345"}'
```

### Search by HAWB Number
```bash
curl -X POST http://localhost:3000/api/v1/search/global \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"query": "HAWB-98765", "search_type": "orders"}'
```

### Search by Account Name
```bash
curl -X POST http://localhost:3000/api/v1/search/global \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"query": "Acme Logistics", "search_type": "accounts"}'
```

### Search by Vehicle VIN
```bash
curl -X POST http://localhost:3000/api/v1/search/global \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"query": "1HGBH41JXMN109186", "search_type": "fleets"}'
```

### Search with Fuzzy Matching
```bash
curl -X POST http://localhost:3000/api/v1/search/global \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"query": "logistcs", "search_type": "accounts"}'
```
Note: Typo "logistcs" will match "logistics"

## Testing

### Test Search Functionality

```bash
rails atlas_search:test_search
```

This will run test queries and verify search is working.

### Verify Indexes

```bash
rails atlas_search:verify
```

## Project Structure

```
app/
├── controllers/
│   ├── api/v1/
│   │   └── search/
│   │       ├── global_controller.rb
│   │       ├── autocomplete_controller.rb
│   │       ├── facets_controller.rb
│   │       └── advanced_controller.rb
├── models/
│   ├── concerns/
│   │   └── searchable.rb
│   ├── order.rb
│   ├── account.rb
│   ├── fleet.rb
│   ├── driver.rb
│   ├── billing.rb
│   ├── invoice.rb
│   └── pod.rb
├── services/
│   └── search/
│       ├── global_search_service.rb
│       ├── autocomplete_service.rb
│       ├── fuzzy_search_service.rb
│       ├── role_based_filter_service.rb
│       └── facet_builder_service.rb
├── serializers/
│   └── search/
│       ├── order_search_serializer.rb
│       ├── account_search_serializer.rb
│       └── ...
└── policies/
    └── search_policy.rb

config/
├── mongoid.yml
├── routes.rb
└── initializers/
    ├── cors.rb
    ├── rack_attack.rb
    └── mongodb_atlas_search.rb

db/
├── seeds.rb
└── atlas_search_indexes/
    ├── orders_search.json
    ├── accounts_search.json
    ├── fleets_search.json
    ├── drivers_search.json
    ├── billings_search.json
    ├── invoices_search.json
    └── pods_search.json

lib/
└── mongodb/
    └── atlas_search_query_builder.rb
```

## Role-Based Access Control

### Access Matrix

| Role | Orders | Accounts | Fleets | Drivers | Billings | Invoices | PODs |
|------|--------|----------|--------|---------|----------|----------|------|
| Admin | All | All | All | All | All | All | All |
| Dispatcher | All/Assigned | - | Read | Read | - | - | Read |
| Billing | Read | All | - | - | All | All | - |
| Driver | Own Only | - | - | Own Only | - | - | Own Only |
| Fleet Manager | By Fleet | - | All | All | - | - | - |

### Filters Applied

- **Dispatchers**: See orders assigned to them or unassigned
- **Drivers**: See only orders/PODs assigned to them
- **Billing**: See all billing-related data
- **Fleet Managers**: See fleet-related data
- **Admin**: No filters

## Performance

- **Search Response Time**: < 500ms (target)
- **Autocomplete Response Time**: < 100ms (target)
- **Index Sync Delay**: 5-10 seconds
- **Concurrent Users**: Supports 100+ concurrent users
- **Write Throughput**: Handles 100 writes/sec at peak

## Deployment

### AWS Deployment

1. **EC2 Instance**: t3.xlarge (4 vCPUs, 16GB RAM)
2. **MongoDB Atlas**: M50 cluster (already configured)
3. **Redis**: ElastiCache t3.small
4. **Load Balancer**: Application Load Balancer

### Environment Variables

Ensure these are set in production:

```env
RAILS_ENV=production
MONGODB_URI=<production-mongodb-uri>
JWT_SECRET_KEY=<strong-secret-key>
REDIS_URL=<production-redis-url>
CORS_ORIGINS=<production-frontend-url>
```

### Deployment Steps

```bash
# 1. Build and deploy to EC2
bundle install --without development test
RAILS_ENV=production rails assets:precompile

# 2. Setup MongoDB Atlas Search indexes (see above)

# 3. Run migrations (if any)
RAILS_ENV=production rails db:seed

# 4. Start server with Puma
bundle exec puma -C config/puma.rb
```

## Troubleshooting

### Search returns empty results

**Problem**: Atlas Search indexes not created or not synced

**Solution**:
1. Run `rails atlas_search:show_indexes`
2. Verify indexes exist in MongoDB Atlas UI
3. Wait 5-10 seconds for index sync after creating data

### "Index not found" error

**Problem**: Search index not created for collection

**Solution**:
1. Go to MongoDB Atlas → Search tab
2. Create index using config from `db/atlas_search_indexes/`
3. Wait for index to build

### Slow search performance

**Problem**: Large result sets or missing indexes

**Solution**:
1. Add pagination (`limit` parameter)
2. Use specific `search_type` instead of "all"
3. Enable Redis caching (`ENABLE_SEARCH_CACHE=true`)
4. Check MongoDB Atlas cluster metrics

### Role-based access not working

**Problem**: User role not set correctly

**Solution**:
1. Verify user role: `User.find_by(email: 'user@example.com').role`
2. Check `can_search_collection?` method
3. Review `RoleBasedFilterService` implementation

## Cost Estimates

| Component | Type | Monthly Cost |
|-----------|------|--------------|
| MongoDB Atlas | M50 | $580 |
| Rails EC2 | t3.xlarge | $120 |
| Redis ElastiCache | t3.small | $24 |
| Load Balancer | ALB | $20 |
| Data Transfer | - | $15 |
| **Total** | - | **~$759** |

## Support & Documentation

- API Documentation: [Swagger/OpenAPI] (TODO)
- Issue Tracker: GitHub Issues
- MongoDB Atlas Docs: https://docs.atlas.mongodb.com/atlas-search/

## License

Proprietary - All Rights Reserved

## Contributors

- Backend Architecture: Claude (AI Assistant)
- Product Requirements: [Your Team]

---

**Built with ❤️ using Ruby on Rails and MongoDB Atlas Search**
