// User and Authentication Types
export type UserRole = 'admin' | 'dispatcher' | 'billing' | 'driver' | 'fleet_manager';

export interface User {
  id: string;
  email: string;
  role: UserRole;
  first_name: string;
  last_name: string;
  full_name?: string;
  driver_id?: string;
}

export interface AuthResponse {
  token: string;
  user: User;
}

export interface LoginCredentials {
  email: string;
  password: string;
}

// Search Types
export type SearchType = 'all' | 'orders' | 'accounts' | 'fleets' | 'drivers' | 'billings' | 'invoices' | 'pods';

export interface SearchFilters {
  status?: string[];
  date_range?: {
    start: string;
    end: string;
  };
}

export interface SearchRequest {
  query: string;
  search_type?: SearchType;
  page?: number;
  limit?: number;
  include_highlights?: boolean;
  include_facets?: boolean;
  include_empty?: boolean;
  filters?: SearchFilters;
}

export interface SearchHighlight {
  [field: string]: string;
}

export interface Account {
  id: string;
  account_name: string;
  account_number: string;
  company_name?: string;
}

export interface Driver {
  id: string;
  full_name: string;
  driver_id: string;
}

export interface Order {
  id: string;
  order_number: string;
  hawb_numbers: string[];
  status: string;
  origin: Address;
  destination: Address;
  account: Account;
  driver?: Driver;
  search_score: number;
  search_highlights: SearchHighlight;
  created_at: string;
  updated_at: string;
}

export interface Address {
  address?: string;
  city?: string;
  state?: string;
  zip?: string;
  country?: string;
}

export interface AccountResult {
  id: string;
  account_name: string;
  account_number: string;
  company_name: string;
  contact_person: string;
  email: string;
  phone: string;
  account_type: string;
  status: string;
  search_score: number;
  search_highlights: SearchHighlight;
}

export interface FleetResult {
  id: string;
  vehicle_name: string;
  vehicle_type: string;
  vin: string;
  license_plate: string;
  make: string;
  model: string;
  year: number;
  status: string;
  display_name: string;
  search_score: number;
  search_highlights: SearchHighlight;
}

export interface DriverResult {
  id: string;
  driver_id: string;
  full_name: string;
  email: string;
  phone: string;
  license_number: string;
  status: string;
  search_score: number;
  search_highlights: SearchHighlight;
}

export interface BillingResult {
  id: string;
  billing_number: string;
  amount: number;
  total_amount: number;
  status: string;
  billing_date: string;
  due_date: string;
  account: Account;
  search_score: number;
  search_highlights: SearchHighlight;
}

export interface InvoiceResult {
  id: string;
  invoice_number: string;
  total_amount: number;
  status: string;
  invoice_date: string;
  due_date: string;
  account: Account;
  search_score: number;
  search_highlights: SearchHighlight;
}

export interface PodResult {
  id: string;
  pod_number: string;
  delivery_date: string;
  recipient_name: string;
  delivery_status: string;
  search_score: number;
  search_highlights: SearchHighlight;
}

export type SearchResultItem = Order | AccountResult | FleetResult | DriverResult | BillingResult | InvoiceResult | PodResult;

export interface CollectionResults {
  count: number;
  items: SearchResultItem[];
}

export interface Pagination {
  current_page: number;
  total_pages: number;
  limit: number;
  total_count: number;
}

export interface FacetValue {
  value: string;
  count: number;
}

export interface Facets {
  [key: string]: FacetValue[];
}

export interface SearchResponse {
  success: boolean;
  query: string;
  total_results: number;
  search_time_ms: number;
  results: {
    [key in SearchType]?: CollectionResults;
  };
  facets: Facets;
  pagination: Pagination;
}

// Autocomplete Types
export interface AutocompleteSuggestion {
  text: string;
  type: string;
  collection: string;
  score: number;
  metadata: {
    id: string;
    score: number;
  };
}

export interface AutocompleteResponse {
  success: boolean;
  query: string;
  suggestions: AutocompleteSuggestion[];
  count: number;
  query_time_ms: number;
}

// Facets Types
export interface FacetsResponse {
  success: boolean;
  collection: string;
  facets: Facets;
}

// API Error
export interface ApiError {
  success: false;
  error: string;
  message?: string;
}
