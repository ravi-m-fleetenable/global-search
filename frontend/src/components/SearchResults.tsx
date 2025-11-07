import React from 'react';
import { SearchResponse, SearchType } from '@/types';
import { FiPackage, FiUsers, FiTruck, FiUser, FiFileText, FiFile, FiCheckCircle } from 'react-icons/fi';
import ResultItem from './ResultItem';
import clsx from 'clsx';

interface SearchResultsProps {
  results: SearchResponse;
  onPageChange?: (page: number) => void;
}

const COLLECTION_CONFIG: Record<string, { icon: any; label: string; color: string }> = {
  orders: { icon: FiPackage, label: 'Orders', color: 'text-blue-600' },
  accounts: { icon: FiUsers, label: 'Accounts', color: 'text-green-600' },
  fleets: { icon: FiTruck, label: 'Fleets', color: 'text-purple-600' },
  drivers: { icon: FiUser, label: 'Drivers', color: 'text-orange-600' },
  billings: { icon: FiFileText, label: 'Billings', color: 'text-red-600' },
  invoices: { icon: FiFile, label: 'Invoices', color: 'text-indigo-600' },
  pods: { icon: FiCheckCircle, label: 'PODs', color: 'text-teal-600' },
};

export default function SearchResults({ results, onPageChange }: SearchResultsProps) {
  if (!results || results.total_results === 0) {
    return (
      <div className="text-center py-12">
        <div className="text-gray-400 mb-4">
          <FiPackage className="w-16 h-16 mx-auto" />
        </div>
        <h3 className="text-lg font-medium text-gray-900 mb-2">No results found</h3>
        <p className="text-gray-500">
          Try adjusting your search query or filters
        </p>
      </div>
    );
  }

  const collectionKeys = Object.keys(results.results) as SearchType[];

  return (
    <div className="space-y-6">
      {/* Search Summary */}
      <div className="bg-white rounded-lg shadow p-4 border border-gray-200">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-lg font-semibold text-gray-900">
              Search Results for "{results.query}"
            </h2>
            <p className="text-sm text-gray-500 mt-1">
              Found {results.total_results} result{results.total_results !== 1 ? 's' : ''} in {results.search_time_ms}ms
            </p>
          </div>

          {/* Collection Summary */}
          <div className="flex gap-3">
            {collectionKeys.map((collectionKey) => {
              const collection = results.results[collectionKey];
              if (!collection || collection.count === 0) return null;

              const config = COLLECTION_CONFIG[collectionKey];
              const Icon = config.icon;

              return (
                <div
                  key={collectionKey}
                  className="flex items-center gap-2 px-3 py-2 bg-gray-50 rounded-lg"
                >
                  <Icon className={clsx('w-4 h-4', config.color)} />
                  <span className="text-sm font-medium text-gray-700">
                    {config.label}
                  </span>
                  <span className="text-sm font-bold text-gray-900">
                    {collection.count}
                  </span>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Results by Collection */}
      {collectionKeys.map((collectionKey) => {
        const collection = results.results[collectionKey];
        if (!collection || collection.count === 0) return null;

        const config = COLLECTION_CONFIG[collectionKey];
        const Icon = config.icon;

        return (
          <div key={collectionKey} className="bg-white rounded-lg shadow border border-gray-200">
            {/* Collection Header */}
            <div className="px-6 py-4 border-b border-gray-200 bg-gray-50">
              <div className="flex items-center gap-3">
                <Icon className={clsx('w-5 h-5', config.color)} />
                <h3 className="text-lg font-semibold text-gray-900">
                  {config.label}
                </h3>
                <span className="text-sm text-gray-500">
                  ({collection.count} result{collection.count !== 1 ? 's' : ''})
                </span>
              </div>
            </div>

            {/* Collection Results */}
            <div className="divide-y divide-gray-200">
              {collection.items.map((item: any) => (
                <ResultItem
                  key={item.id}
                  item={item}
                  collectionType={collectionKey}
                />
              ))}
            </div>
          </div>
        );
      })}

      {/* Pagination */}
      {results.pagination && results.pagination.total_pages > 1 && (
        <div className="bg-white rounded-lg shadow p-4 border border-gray-200">
          <div className="flex items-center justify-between">
            <div className="text-sm text-gray-700">
              Page {results.pagination.current_page} of {results.pagination.total_pages}
            </div>

            <div className="flex gap-2">
              <button
                onClick={() => onPageChange?.(results.pagination.current_page - 1)}
                disabled={results.pagination.current_page === 1}
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Previous
              </button>

              {/* Page Numbers */}
              <div className="flex gap-1">
                {Array.from({ length: Math.min(5, results.pagination.total_pages) }, (_, i) => {
                  let pageNum;
                  if (results.pagination.total_pages <= 5) {
                    pageNum = i + 1;
                  } else if (results.pagination.current_page <= 3) {
                    pageNum = i + 1;
                  } else if (results.pagination.current_page >= results.pagination.total_pages - 2) {
                    pageNum = results.pagination.total_pages - 4 + i;
                  } else {
                    pageNum = results.pagination.current_page - 2 + i;
                  }

                  return (
                    <button
                      key={pageNum}
                      onClick={() => onPageChange?.(pageNum)}
                      className={clsx(
                        'px-3 py-2 text-sm font-medium rounded-md',
                        pageNum === results.pagination.current_page
                          ? 'bg-blue-600 text-white'
                          : 'text-gray-700 bg-white border border-gray-300 hover:bg-gray-50'
                      )}
                    >
                      {pageNum}
                    </button>
                  );
                })}
              </div>

              <button
                onClick={() => onPageChange?.(results.pagination.current_page + 1)}
                disabled={results.pagination.current_page === results.pagination.total_pages}
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Next
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
