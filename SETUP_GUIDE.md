# Setup Guide - Global Search API

This guide will walk you through setting up the Global Search API from scratch.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Development Setup](#local-development-setup)
3. [MongoDB Atlas Configuration](#mongodb-atlas-configuration)
4. [Creating Search Indexes](#creating-search-indexes)
5. [Redis Setup](#redis-setup)
6. [Testing the Installation](#testing-the-installation)
7. [Production Deployment](#production-deployment)

---

## Prerequisites

### Required Software

- **Ruby 3.2.2**
  ```bash
  # Using rbenv
  rbenv install 3.2.2
  rbenv global 3.2.2

  # Or using rvm
  rvm install 3.2.2
  rvm use 3.2.2 --default
  ```

- **Bundler**
  ```bash
  gem install bundler
  ```

- **MongoDB Atlas Account**
  - Sign up at https://www.mongodb.com/cloud/atlas
  - Create M50+ cluster (required for Atlas Search)

- **Redis** (optional, for caching)
  ```bash
  # macOS
  brew install redis
  brew services start redis

  # Ubuntu/Debian
  sudo apt-get install redis-server
  sudo systemctl start redis
  ```

---

## Local Development Setup

### 1. Clone and Install

```bash
# Clone repository
git clone <repository-url>
cd global-search

# Install gems
bundle install
```

### 2. Environment Configuration

Create `.env` file:

```bash
cp .env.example .env
```

Edit `.env`:

```env
# MongoDB Atlas Configuration
MONGODB_URI=mongodb+srv://USERNAME:PASSWORD@cluster.mongodb.net/logistics_development?retryWrites=true&w=majority
MONGODB_DATABASE=logistics_development

# Redis Configuration (use localhost for development)
REDIS_URL=redis://localhost:6379/0

# JWT Configuration
JWT_SECRET_KEY=$(openssl rand -hex 64)
JWT_EXPIRATION_HOURS=24

# Rails Configuration
RAILS_ENV=development
RAILS_MAX_THREADS=5

# CORS Configuration
CORS_ORIGINS=http://localhost:3000,http://localhost:3001

# Search Configuration
SEARCH_RESULTS_PER_PAGE=20
AUTOCOMPLETE_MIN_CHARS=2
AUTOCOMPLETE_MAX_RESULTS=10

# Fuzzy Search Configuration
FUZZY_MAX_EDITS=2
FUZZY_PREFIX_LENGTH=0
FUZZY_MAX_EXPANSIONS=50

# Cache Configuration
ENABLE_SEARCH_CACHE=true
SEARCH_CACHE_TTL_SECONDS=300
```

**Important**: Replace `USERNAME` and `PASSWORD` with your MongoDB Atlas credentials.

---

## MongoDB Atlas Configuration

### 1. Create MongoDB Atlas Cluster

1. Go to https://cloud.mongodb.com/
2. Click **"Build a Database"**
3. Choose **"M50 Dedicated"** (required for Atlas Search)
4. Select AWS as cloud provider
5. Choose region (e.g., us-east-1)
6. Click **"Create Cluster"**
7. Wait 7-10 minutes for cluster to deploy

### 2. Configure Network Access

1. Go to **Network Access**
2. Click **"Add IP Address"**
3. For development: Click **"Allow Access from Anywhere"** (0.0.0.0/0)
4. For production: Add specific IP addresses only

### 3. Create Database User

1. Go to **Database Access**
2. Click **"Add New Database User"**
3. Choose **"Password"** authentication
4. Set username and password
5. Select **"Read and write to any database"**
6. Click **"Add User"**

### 4. Get Connection String

1. Click **"Connect"** on your cluster
2. Choose **"Connect your application"**
3. Select **"Ruby"** driver version **"2.5 or later"**
4. Copy connection string
5. Replace `<password>` with your password
6. Add database name: `/logistics_development`

Example:
```
mongodb+srv://admin:MyP@ssw0rd@cluster0.abc123.mongodb.net/logistics_development?retryWrites=true&w=majority
```

---

## Creating Search Indexes

This is the **MOST IMPORTANT** step! Search will not work without these indexes.

### Method 1: Via MongoDB Atlas UI (Recommended)

For each collection, follow these steps:

#### Step-by-Step for Orders Collection:

1. Go to your MongoDB Atlas cluster
2. Click **"Search"** tab (not "Browse Collections")
3. Click **"Create Search Index"**
4. Choose **"JSON Editor"**
5. Select Database: `logistics_development`
6. Select Collection: `orders`
7. Copy content from `db/atlas_search_indexes/orders_search.json`
8. Paste into the JSON editor
9. Click **"Next"**
10. Click **"Create Search Index"**
11. Wait for status to change from "Building" to "Active" (~1-2 minutes)

#### Repeat for All Collections:

- ✅ orders → `db/atlas_search_indexes/orders_search.json`
- ✅ accounts → `db/atlas_search_indexes/accounts_search.json`
- ✅ fleets → `db/atlas_search_indexes/fleets_search.json`
- ✅ drivers → `db/atlas_search_indexes/drivers_search.json`
- ✅ billings → `db/atlas_search_indexes/billings_search.json`
- ✅ invoices → `db/atlas_search_indexes/invoices_search.json`
- ✅ pods → `db/atlas_search_indexes/pods_search.json`

### Method 2: Display Index Configurations

Use this command to display all index configurations:

```bash
rails atlas_search:show_indexes
```

This will print all index configurations to copy/paste into Atlas UI.

### Verify Indexes Created

```bash
rails atlas_search:verify
```

Or check manually in Atlas:
1. Go to **Search** tab
2. You should see 7 indexes, all with status **"Active"**

---

## Redis Setup

### Development

```bash
# macOS
brew install redis
brew services start redis

# Test connection
redis-cli ping
# Should return: PONG
```

### Docker (Alternative)

```bash
docker run -d -p 6379:6379 redis:7-alpine
```

### Verify Connection

```bash
rails console

# In Rails console:
Rails.cache.write('test', 'hello')
Rails.cache.read('test')
# Should return: "hello"
```

---

## Testing the Installation

### 1. Seed Database

```bash
rails db:seed
```

Expected output:
```
Clearing existing data...
Creating accounts...
Created 10 accounts
Creating drivers...
Created 20 drivers
Creating fleets...
Created 15 fleets
Creating users...
Created 7 users
Creating orders...
Created 100 orders
Creating PODs...
Created XX PODs
Creating billings...
Created 30 billings
Creating invoices...
Created 40 invoices

================================
Seed data created successfully!
================================
```

### 2. Start Rails Server

```bash
rails server
```

Server should start on: `http://localhost:3000`

### 3. Test Health Endpoint

```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2025-01-07T...",
  "version": "1.0.0",
  "services": {
    "mongodb": {
      "status": "ok",
      "response_time_ms": 45.2
    },
    "redis": {
      "status": "ok",
      "response_time_ms": 2.1
    }
  }
}
```

### 4. Test Authentication

```bash
curl -X POST http://localhost:3000/api/v1/users/sign_in \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "admin@logistics.com",
      "password": "password123"
    }
  }'
```

Save the returned token for next steps.

### 5. Test Search

```bash
# Replace <TOKEN> with actual token from step 4
curl -X POST http://localhost:3000/api/v1/search/global \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "ORD",
    "search_type": "orders",
    "limit": 5
  }'
```

If you get "index not found" error:
- ✅ Verify Atlas Search indexes are created
- ✅ Wait 5-10 seconds for index sync
- ✅ Check database name matches in indexes

### 6. Run Automated Tests

```bash
rails atlas_search:test_search
```

This runs several test queries and reports results.

---

## Production Deployment

### AWS EC2 Setup

#### 1. Launch EC2 Instance

- **Instance Type**: t3.xlarge (4 vCPUs, 16GB RAM)
- **AMI**: Ubuntu 22.04 LTS
- **Storage**: 50GB SSD
- **Security Group**: Open ports 22 (SSH), 80 (HTTP), 443 (HTTPS)

#### 2. Install Dependencies

```bash
# Connect via SSH
ssh -i your-key.pem ubuntu@<ec2-public-ip>

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Ruby dependencies
sudo apt-get install -y git curl libssl-dev libreadline-dev zlib1g-dev \
  autoconf bison build-essential libyaml-dev libreadline-dev \
  libncurses5-dev libffi-dev libgdbm-dev

# Install rbenv
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash

# Add to ~/.bashrc
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

# Install Ruby 3.2.2
rbenv install 3.2.2
rbenv global 3.2.2

# Install Bundler
gem install bundler
```

#### 3. Deploy Application

```bash
# Clone repository
git clone <repository-url> /var/www/logistics-search
cd /var/www/logistics-search

# Install gems
bundle install --without development test

# Set environment variables
sudo nano /etc/environment
# Add all production environment variables

# Create .env file
cp .env.example .env
nano .env
# Configure with production values
```

#### 4. Setup Systemd Service

Create `/etc/systemd/system/logistics-search.service`:

```ini
[Unit]
Description=Logistics Search API
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/var/www/logistics-search
Environment="RAILS_ENV=production"
ExecStart=/home/ubuntu/.rbenv/shims/bundle exec puma -C config/puma.rb
Restart=always

[Install]
WantedBy=multi-user.target
```

Start service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable logistics-search
sudo systemctl start logistics-search
sudo systemctl status logistics-search
```

### MongoDB Atlas Production Setup

1. **Create Production Cluster**: M50 or higher
2. **Enable Backup**: Continuous backup recommended
3. **Network Access**: Add EC2 IP addresses only
4. **Create Search Indexes**: Same as development (see above)
5. **Connection String**: Use production database name

### ElastiCache Redis Setup

1. Go to AWS ElastiCache console
2. Create Redis cluster: cache.t3.small
3. Note endpoint: `xxxx.cache.amazonaws.com:6379`
4. Update `REDIS_URL` in production `.env`

### Load Balancer Setup

1. Create Application Load Balancer
2. Add target group pointing to EC2 instance
3. Configure health check: `/health`
4. Add SSL certificate (ACM)
5. Update CORS_ORIGINS with ALB DNS

---

## Monitoring

### Application Logs

```bash
# View logs
tail -f log/production.log

# View Puma logs
sudo journalctl -u logistics-search -f
```

### MongoDB Atlas Monitoring

1. Go to Atlas dashboard
2. Click **"Metrics"** tab
3. Monitor:
   - CPU utilization
   - Memory usage
   - Connections
   - Search index performance

### Search Performance

```bash
# In Rails console
Search::GlobalSearchService.new('test', User.first).search
# Check search_time_ms in response
```

---

## Troubleshooting

### Issue: "Could not connect to MongoDB"

**Solution**:
- Check `MONGODB_URI` is correct
- Verify IP whitelist in Atlas Network Access
- Test connection: `rails console` then `Mongoid.default_client.command(ping: 1)`

### Issue: "Index not found" in search

**Solution**:
- Run `rails atlas_search:show_indexes`
- Verify all 7 indexes created in Atlas UI
- Wait 1-2 minutes for indexes to build
- Check collection names match exactly

### Issue: "Redis connection refused"

**Solution**:
- Check Redis is running: `redis-cli ping`
- Verify `REDIS_URL` is correct
- Disable caching temporarily: `ENABLE_SEARCH_CACHE=false`

### Issue: Search returns no results

**Solution**:
- Verify data exists: `Order.count`
- Check user permissions: `user.can_search_collection?('orders')`
- Test without role filters (as admin user)
- Check Atlas Search index status (should be "Active")

---

## Next Steps

After setup is complete:

1. ✅ Integrate with ReactJS frontend
2. ✅ Set up CI/CD pipeline
3. ✅ Configure monitoring alerts
4. ✅ Implement backup strategy
5. ✅ Load testing with realistic data
6. ✅ Security audit
7. ✅ API documentation (Swagger)

---

Need help? Check:
- README.md for API usage examples
- MongoDB Atlas Search documentation
- GitHub issues

**Happy Searching! 🔍**
