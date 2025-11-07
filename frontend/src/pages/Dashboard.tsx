import React, { useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import { useSearch } from '@/hooks/useSearch';
import SearchBar from '@/components/SearchBar';
import SearchResults from '@/components/SearchResults';
import { SearchType } from '@/types';
import { FiLogOut, FiUser } from 'react-icons/fi';

export default function Dashboard() {
  const { user, logout } = useAuth();
  const { results, isLoading, search } = useSearch();
  const [currentPage, setCurrentPage] = useState(1);
  const [lastQuery, setLastQuery] = useState('');
  const [lastSearchType, setLastSearchType] = useState<SearchType>('all');

  const handleSearch = async (query: string, searchType: SearchType) => {
    setLastQuery(query);
    setLastSearchType(searchType);
    setCurrentPage(1);

    await search({
      query,
      search_type: searchType,
      page: 1,
      limit: 20,
      include_highlights: true,
      include_facets: false,
    });
  };

  const handlePageChange = async (page: number) => {
    setCurrentPage(page);

    await search({
      query: lastQuery,
      search_type: lastSearchType,
      page,
      limit: 20,
      include_highlights: true,
      include_facets: false,
    });
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">
                Logistics Search
              </h1>
              <p className="text-sm text-gray-500">
                Global search across all collections
              </p>
            </div>

            {/* User Menu */}
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2 px-4 py-2 bg-gray-50 rounded-lg">
                <FiUser className="w-4 h-4 text-gray-600" />
                <div className="text-sm">
                  <div className="font-medium text-gray-900">
                    {user?.first_name} {user?.last_name}
                  </div>
                  <div className="text-xs text-gray-500 capitalize">
                    {user?.role?.replace('_', ' ')}
                  </div>
                </div>
              </div>

              <button
                onClick={logout}
                className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
              >
                <FiLogOut className="w-4 h-4" />
                <span>Logout</span>
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Search Bar */}
        <div className="mb-8">
          <SearchBar
            onSearch={handleSearch}
            isLoading={isLoading}
            placeholder="Search orders, accounts, vehicles, drivers..."
          />
        </div>

        {/* Welcome Message */}
        {!results && !isLoading && (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8">
            <div className="text-center">
              <h2 className="text-xl font-semibold text-gray-900 mb-2">
                Welcome to Logistics Search
              </h2>
              <p className="text-gray-600 mb-6">
                Start searching across orders, accounts, fleets, drivers, billings, invoices, and PODs
              </p>

              <div className="grid grid-cols-2 md:grid-cols-4 gap-4 max-w-2xl mx-auto">
                <div className="p-4 bg-blue-50 rounded-lg">
                  <div className="text-2xl font-bold text-blue-600 mb-1">Orders</div>
                  <div className="text-sm text-gray-600">Search by order number or HAWB</div>
                </div>
                <div className="p-4 bg-green-50 rounded-lg">
                  <div className="text-2xl font-bold text-green-600 mb-1">Accounts</div>
                  <div className="text-sm text-gray-600">Find accounts by name or number</div>
                </div>
                <div className="p-4 bg-purple-50 rounded-lg">
                  <div className="text-2xl font-bold text-purple-600 mb-1">Fleets</div>
                  <div className="text-sm text-gray-600">Search vehicles by VIN or license</div>
                </div>
                <div className="p-4 bg-orange-50 rounded-lg">
                  <div className="text-2xl font-bold text-orange-600 mb-1">Drivers</div>
                  <div className="text-sm text-gray-600">Find drivers by name or ID</div>
                </div>
              </div>

              <div className="mt-8 text-sm text-gray-500">
                <p className="mb-2">💡 <strong>Tips:</strong></p>
                <ul className="space-y-1">
                  <li>• Use the dropdown to search specific collections</li>
                  <li>• Autocomplete will suggest results as you type</li>
                  <li>• Fuzzy search handles typos automatically</li>
                  <li>• Results are filtered based on your role: <span className="font-semibold capitalize">{user?.role?.replace('_', ' ')}</span></li>
                </ul>
              </div>
            </div>
          </div>
        )}

        {/* Loading State */}
        {isLoading && (
          <div className="flex justify-center items-center py-12">
            <div className="text-center">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
              <p className="text-gray-600">Searching...</p>
            </div>
          </div>
        )}

        {/* Search Results */}
        {results && !isLoading && (
          <SearchResults results={results} onPageChange={handlePageChange} />
        )}
      </main>

      {/* Footer */}
      <footer className="bg-white border-t border-gray-200 mt-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex justify-between items-center text-sm text-gray-500">
            <div>
              © 2025 Logistics Search. All rights reserved.
            </div>
            <div className="flex gap-6">
              <a href="#" className="hover:text-gray-700 transition-colors">Documentation</a>
              <a href="#" className="hover:text-gray-700 transition-colors">API</a>
              <a href="#" className="hover:text-gray-700 transition-colors">Support</a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
