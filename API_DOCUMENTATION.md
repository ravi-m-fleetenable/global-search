# API Documentation - Global Search API

## Base URL
```
Development: http://localhost:3000
Production: https://api.yourlogistics.com
```

## Authentication

All API requests require authentication using JWT Bearer token.

### Get Authentication Token

**Endpoint:** `POST /api/v1/users/sign_in`

**Request:**
```json
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
  "token": "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI2NWE...",
  "user": {
    "id": "65a1b2c3d4e5f6g7h8i9j0k1",
    "email": "admin@logistics.com",
    "role": "admin",
    "first_name": "Admin",
    "last_name": "User"
  }
}
```

**Using the Token:**
Include in all subsequent requests:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI2NWE...
```

---

## Global Search

### Search Across All Collections

**Endpoint:** `POST /api/v1/search/global`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "query": "ORD-12345",
  "search_type": "all",
  "page": 1,
  "limit": 20,
  "include_highlights": true,
  "include_facets": false,
  "include_empty": false,
  "filters": {
    "status": ["active", "pending"]
  }
}
```

**Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| query | string | Yes | Search query text |
| search_type | string | No | Collection to search: "all", "orders", "accounts", "fleets", "drivers", "billings", "invoices", "pods" |
| page | integer | No | Page number (default: 1) |
| limit | integer | No | Results per page (default: 20, max: 100) |
| include_highlights | boolean | No | Include highlighted matching text (default: true) |
| include_facets | boolean | No | Include faceted counts (default: false) |
| include_empty | boolean | No | Include collections with 0 results (default: false) |
| filters.status | array | No | Filter by status values |

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
          "id": "65a1b2c3d4e5f6g7h8i9j0k1",
          "order_number": "ORD-12345",
          "hawb_numbers": ["HAWB-98765"],
          "status": "in_transit",
          "origin": {
            "address": "123 Main St",
            "city": "New York",
            "state": "NY",
            "zip": "10001",
            "country": "USA"
          },
          "destination": {
            "address": "456 Oak Ave",
            "city": "Los Angeles",
            "state": "CA",
            "zip": "90001",
            "country": "USA"
          },
          "account": {
            "id": "65a1b2c3d4e5f6g7h8i9j0k2",
            "account_name": "Acme Logistics",
            "account_number": "ACC-2025-A1B2C3D4"
          },
          "driver": {
            "id": "65a1b2c3d4e5f6g7h8i9j0k3",
            "full_name": "John Driver",
            "driver_id": "DRV-2025-X1Y2Z3"
          },
          "search_score": 8.5,
          "search_highlights": {
            "order_number": "<em>ORD-12345</em>"
          },
          "created_at": "2025-01-07T10:30:00Z",
          "updated_at": "2025-01-07T15:45:00Z"
        }
      ]
    }
  },
  "facets": {},
  "pagination": {
    "current_page": 1,
    "total_pages": 1,
    "limit": 20,
    "total_count": 1
  }
}
```

**Status Codes:**
- `200 OK`: Search successful
- `400 Bad Request`: Missing or invalid parameters
- `401 Unauthorized`: Invalid or missing token
- `403 Forbidden`: User lacks permission for requested collection
- `422 Unprocessable Entity`: Search error

---

## Autocomplete

### Get Search Suggestions

**Endpoint:** `GET /api/v1/search/autocomplete`

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| q | string | Yes | Search query (minimum 2 characters) |
| type | string | Yes | Collection: "orders", "accounts", "fleets", "drivers", "billings", "invoices", "pods" |
| limit | integer | No | Max suggestions to return (default: 10, max: 50) |
| min_chars | integer | No | Minimum query length (default: 2) |

**Example Request:**
```
GET /api/v1/search/autocomplete?q=ord&type=orders&limit=10
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
        "id": "65a1b2c3d4e5f6g7h8i9j0k1",
        "score": 9.2
      }
    },
    {
      "text": "ORD-20250106-X9Y8Z7W6",
      "type": "order_number",
      "collection": "orders",
      "score": 8.8,
      "metadata": {
        "id": "65a1b2c3d4e5f6g7h8i9j0k2",
        "score": 8.8
      }
    }
  ],
  "count": 2,
  "query_time_ms": 45
}
```

**Status Codes:**
- `200 OK`: Autocomplete successful
- `400 Bad Request`: Missing or invalid parameters
- `401 Unauthorized`: Invalid or missing token

---

## Faceted Search

### Get Facets for Collection

**Endpoint:** `GET /api/v1/search/facets`

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| collection | string | Yes | Collection name: "orders", "accounts", "fleets", "drivers", "billings", "invoices", "pods" |

**Example Request:**
```
GET /api/v1/search/facets?collection=orders
```

**Response:**
```json
{
  "success": true,
  "collection": "orders",
  "facets": {
    "status": [
      {"value": "pending", "count": 15},
      {"value": "confirmed", "count": 12},
      {"value": "in_transit", "count": 30},
      {"value": "delivered", "count": 50},
      {"value": "cancelled", "count": 3}
    ],
    "createdDate": [
      {"value": "last_week", "count": 25},
      {"value": "last_month", "count": 65},
      {"value": "last_3_months", "count": 95}
    ]
  }
}
```

**Available Facets by Collection:**

| Collection | Facets |
|------------|--------|
| orders | status, createdDate |
| accounts | accountType, status |
| fleets | vehicleType, status, make |
| drivers | status |
| billings | status, billingDate |
| invoices | status, invoiceDate |
| pods | deliveryStatus |

**Status Codes:**
- `200 OK`: Facets retrieved successfully
- `400 Bad Request`: Invalid collection name
- `401 Unauthorized`: Invalid or missing token
- `403 Forbidden`: User lacks access to collection

---

## Search Examples

### Example 1: Search Orders by Number

```bash
curl -X POST http://localhost:3000/api/v1/search/global \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "ORD-12345",
    "search_type": "orders"
  }'
```

### Example 2: Search with Filters

```bash
curl -X POST http://localhost:3000/api/v1/search/global \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "logistics",
    "search_type": "accounts",
    "filters": {
      "status": ["active"]
    }
  }'
```

### Example 3: Fuzzy Search (Typo Tolerance)

```bash
curl -X POST http://localhost:3000/api/v1/search/global \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "logistcs",
    "search_type": "accounts"
  }'
```
Note: "logistcs" will match "logistics"

### Example 4: Autocomplete

```bash
curl "http://localhost:3000/api/v1/search/autocomplete?q=toyota&type=fleets" \
  -H "Authorization: Bearer <token>"
```

### Example 5: Get Facets

```bash
curl "http://localhost:3000/api/v1/search/facets?collection=orders" \
  -H "Authorization: Bearer <token>"
```

---

## Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "error": "Bad request",
  "message": "query parameter is required"
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "error": "Unauthorized",
  "message": "Invalid or expired token"
}
```

### 403 Forbidden
```json
{
  "success": false,
  "error": "Unauthorized access",
  "message": "You do not have access to this collection"
}
```

### 404 Not Found
```json
{
  "success": false,
  "error": "Resource not found",
  "message": "The requested resource was not found"
}
```

### 422 Unprocessable Entity
```json
{
  "success": false,
  "error": "An error occurred during search",
  "query": "test"
}
```

### 429 Too Many Requests
```json
{
  "error": "Rate limit exceeded. Please try again later."
}
```

---

## Rate Limiting

- **Global**: 300 requests per minute per IP
- **Search**: 100 requests per minute per IP
- **Autocomplete**: 200 requests per minute per IP
- **Login**: 5 attempts per 20 seconds per IP

When rate limited, API returns `429 Too Many Requests` with `Retry-After` header.

---

## Searchable Fields by Collection

### Orders
- order_number
- hawb_numbers
- status

### Accounts
- account_name
- company_name
- account_number
- contact_person
- email

### Fleets
- vehicle_name
- vin
- license_plate
- make
- model

### Drivers
- full_name
- first_name
- last_name
- license_number
- driver_id
- email

### Billings
- billing_number
- status

### Invoices
- invoice_number
- status

### PODs
- pod_number
- recipient_name
- delivery_status

---

## Role-Based Access

Different user roles have different search permissions:

| Role | Collections Accessible |
|------|------------------------|
| Admin | All collections |
| Dispatcher | orders, drivers, fleets, pods |
| Billing | billings, invoices, orders (read-only), accounts |
| Driver | orders (own only), pods (own only), drivers (own record) |
| Fleet Manager | fleets, drivers, orders (by fleet) |

---

## Best Practices

1. **Use Autocomplete for Type-ahead**: Provides better UX with instant suggestions
2. **Implement Debouncing**: Wait 300ms before triggering autocomplete
3. **Paginate Results**: Use reasonable `limit` values (20-50)
4. **Cache Results**: Enable Redis caching for better performance
5. **Use Specific Search Types**: Searching specific collections is faster than "all"
6. **Handle Errors Gracefully**: Always check `success` field in response
7. **Respect Rate Limits**: Implement exponential backoff on rate limit errors

---

## Webhook Support

Coming soon: Webhooks for real-time notifications when search index updates complete.

---

## Support

For API support:
- GitHub Issues: [repository-url]/issues
- Email: support@yourlogistics.com
- Documentation: https://docs.yourlogistics.com
