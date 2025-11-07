# Logistics Search - Frontend

Modern, responsive React/TypeScript frontend for the Global Search system built with Vite, Tailwind CSS, and React Router.

## Features

- 🔍 **Real-time Global Search** with autocomplete
- ⚡ **Fast & Responsive** UI built with Vite
- 🎨 **Modern Design** with Tailwind CSS
- 🔐 **Secure Authentication** with JWT
- 👥 **Role-Based Access Control**
- 📱 **Responsive** design for all devices
- 🚀 **Type-Safe** with TypeScript
- 💡 **Fuzzy Search** with typo tolerance
- 🎯 **Highlighted Results** with matched terms
- 📄 **Pagination** for large result sets

## Tech Stack

- **React 18** - UI library
- **TypeScript** - Type safety
- **Vite** - Build tool & dev server
- **Tailwind CSS** - Styling
- **React Router** - Routing
- **Axios** - API client
- **React Icons** - Icon library
- **React Toastify** - Notifications
- **date-fns** - Date formatting

## Prerequisites

- Node.js 18+ and npm/yarn
- Rails backend running on `http://localhost:3000`

## Quick Start

### 1. Install Dependencies

```bash
cd frontend
npm install
```

### 2. Configure Environment

```bash
cp .env.example .env
```

Edit `.env`:
```env
VITE_API_BASE_URL=http://localhost:3000
VITE_API_TIMEOUT=10000
```

### 3. Start Development Server

```bash
npm run dev
```

Frontend will be available at: `http://localhost:3001`

## Project Structure

```
frontend/
├── src/
│   ├── components/          # Reusable UI components
│   │   ├── SearchBar.tsx    # Search input with autocomplete
│   │   ├── SearchResults.tsx # Results container
│   │   └── ResultItem.tsx   # Individual result display
│   ├── context/
│   │   └── AuthContext.tsx  # Authentication state management
│   ├── hooks/
│   │   ├── useSearch.ts     # Search functionality hook
│   │   ├── useAutocomplete.ts # Autocomplete hook
│   │   └── useDebounce.ts   # Debounce hook
│   ├── pages/
│   │   ├── Login.tsx        # Login page
│   │   └── Dashboard.tsx    # Main search dashboard
│   ├── services/
│   │   └── api.ts           # API client and service layer
│   ├── types/
│   │   └── index.ts         # TypeScript type definitions
│   ├── App.tsx              # Main app component with routing
│   ├── main.tsx             # App entry point
│   └── index.css            # Global styles
├── public/                  # Static assets
├── index.html              # HTML template
├── vite.config.ts          # Vite configuration
├── tailwind.config.js      # Tailwind configuration
├── tsconfig.json           # TypeScript configuration
└── package.json            # Dependencies and scripts
```

## Available Scripts

```bash
# Development
npm run dev              # Start dev server (http://localhost:3001)

# Production
npm run build            # Build for production
npm run preview          # Preview production build

# Linting
npm run lint             # Run ESLint
```

## Usage

### Login

The app includes demo users with different roles:

| Role | Email | Password | Access |
|------|-------|----------|--------|
| Admin | admin@logistics.com | password123 | Full access to all collections |
| Dispatcher | dispatcher@logistics.com | password123 | Orders, Drivers, Fleets, PODs |
| Billing | billing@logistics.com | password123 | Billings, Invoices, Orders, Accounts |
| Driver | driver1@logistics.com | password123 | Own orders and PODs only |

### Search Features

#### 1. **Global Search**
- Select "All" to search across all collections
- Or choose specific collection type from dropdown
- Results are automatically filtered based on user role

#### 2. **Autocomplete**
- Start typing (minimum 2 characters)
- Suggestions appear instantly
- Navigate with arrow keys
- Press Enter to select

#### 3. **Search Results**
- Results grouped by collection type
- Matched terms highlighted in yellow
- Relevance score displayed
- Click through pagination for more results

#### 4. **Fuzzy Search**
- Automatic typo tolerance
- "logistcs" matches "logistics"
- "vehicl" matches "vehicle"
- Powered by Levenshtein distance algorithm

## API Integration

The frontend communicates with the Rails backend API:

### Base URL
```typescript
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000';
```

### Authentication
All API requests include JWT token in headers:
```typescript
headers: {
  'Authorization': `Bearer ${token}`
}
```

### Main Endpoints Used

```typescript
// Login
POST /api/v1/users/sign_in
Body: { user: { email, password } }

// Global Search
POST /api/v1/search/global
Body: { query, search_type, page, limit }

// Autocomplete
GET /api/v1/search/autocomplete?q={query}&type={type}

// Facets
GET /api/v1/search/facets?collection={collection}
```

## Component Details

### SearchBar Component

Features:
- Real-time autocomplete with debouncing (300ms)
- Search type selector
- Keyboard navigation (↑↓ arrows, Enter, Escape)
- Loading states
- Clear button

Usage:
```tsx
<SearchBar
  onSearch={(query, type) => handleSearch(query, type)}
  isLoading={isSearching}
  placeholder="Search orders, accounts..."
/>
```

### SearchResults Component

Features:
- Grouped results by collection
- Pagination controls
- Result count and search time
- Empty state handling

Usage:
```tsx
<SearchResults
  results={searchResults}
  onPageChange={(page) => handlePageChange(page)}
/>
```

### ResultItem Component

Features:
- Conditional rendering based on collection type
- Highlighted search terms
- Status badges
- Formatted dates and currencies
- Responsive layout

## Styling

### Tailwind CSS

The app uses Tailwind CSS for styling with a custom configuration:

```javascript
// tailwind.config.js
theme: {
  extend: {
    colors: {
      primary: { /* Blue shades */ }
    }
  }
}
```

### Custom Styles

- Highlighted search terms: Yellow background
- Custom scrollbar styling
- Toast notification customization
- Responsive breakpoints

## State Management

### Auth State (AuthContext)

```typescript
const { user, isAuthenticated, login, logout, hasRole, canAccessCollection } = useAuth();
```

### Search State (useSearch hook)

```typescript
const { results, isLoading, error, search, clearResults } = useSearch();
```

### Autocomplete State (useAutocomplete hook)

```typescript
const { suggestions, isLoading, clearSuggestions } = useAutocomplete(query, collection);
```

## Type Safety

All types are defined in `src/types/index.ts`:

```typescript
// User types
interface User { id, email, role, first_name, last_name }

// Search types
interface SearchRequest { query, search_type, page, limit }
interface SearchResponse { success, query, total_results, results, pagination }

// Result types
interface Order { id, order_number, hawb_numbers, status, ... }
interface Account { id, account_name, account_number, ... }
// ... and more
```

## Role-Based Access

Different user roles see different results:

```typescript
const canAccessCollection = (collection: string): boolean => {
  const accessMap = {
    orders: ['admin', 'dispatcher', 'billing', 'driver', 'fleet_manager'],
    accounts: ['admin', 'billing'],
    fleets: ['admin', 'dispatcher', 'fleet_manager'],
    drivers: ['admin', 'dispatcher', 'driver', 'fleet_manager'],
    billings: ['admin', 'billing'],
    invoices: ['admin', 'billing'],
    pods: ['admin', 'dispatcher', 'driver'],
  };

  return accessMap[collection]?.includes(user.role) || false;
};
```

## Building for Production

### Build

```bash
npm run build
```

Outputs to `dist/` directory.

### Preview Build

```bash
npm run preview
```

### Deploy

The `dist/` folder can be deployed to:
- AWS S3 + CloudFront
- Vercel
- Netlify
- Any static hosting service

### Environment Variables for Production

```env
VITE_API_BASE_URL=https://api.yourlogistics.com
VITE_API_TIMEOUT=10000
```

## Performance Optimization

- **Code Splitting**: Automatic with Vite
- **Lazy Loading**: Components loaded on demand
- **Debounced Autocomplete**: Reduces API calls
- **Memoization**: React hooks optimize re-renders
- **Tree Shaking**: Removes unused code
- **Asset Optimization**: Vite optimizes images and fonts

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## Troubleshooting

### Issue: "Cannot connect to backend"

**Solution:**
- Ensure Rails backend is running on `http://localhost:3000`
- Check CORS settings in Rails backend
- Verify `VITE_API_BASE_URL` in `.env`

### Issue: "Autocomplete not working"

**Solution:**
- Check minimum character length (default: 2)
- Ensure search type is not "all" (autocomplete disabled for "all")
- Verify backend autocomplete endpoint is accessible

### Issue: "Login fails"

**Solution:**
- Check email and password
- Verify Rails backend is seeded with demo users
- Check browser console for error details
- Clear localStorage and try again

### Issue: "Search results not displaying"

**Solution:**
- Check user role permissions
- Verify MongoDB Atlas Search indexes are created
- Check backend logs for errors
- Try searching with admin user

## Development Tips

1. **Hot Reload**: Vite provides instant hot reload during development
2. **React DevTools**: Install browser extension for debugging
3. **Network Tab**: Monitor API calls in browser DevTools
4. **TypeScript**: Use `npm run dev` to see type errors in real-time

## Future Enhancements

- [ ] Advanced filters UI
- [ ] Saved searches
- [ ] Export results to CSV/PDF
- [ ] Dark mode
- [ ] Mobile app (React Native)
- [ ] Offline support
- [ ] Voice search
- [ ] Search analytics dashboard

## Contributing

1. Create feature branch
2. Make changes
3. Test thoroughly
4. Create pull request

## License

Proprietary - All Rights Reserved

## Support

For issues and questions:
- Backend API: See `../README.md`
- Frontend issues: Check browser console
- Authentication: Verify JWT token in localStorage

---

**Built with ❤️ using React, TypeScript, and Tailwind CSS**
