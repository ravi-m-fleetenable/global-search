import React, { useState, useRef, useEffect } from 'react';
import { FiSearch, FiX } from 'react-icons/fi';
import { SearchType } from '@/types';
import { useAutocomplete } from '@/hooks/useAutocomplete';
import clsx from 'clsx';

interface SearchBarProps {
  onSearch: (query: string, searchType: SearchType) => void;
  isLoading?: boolean;
  placeholder?: string;
}

const SEARCH_TYPES: { value: SearchType; label: string }[] = [
  { value: 'all', label: 'All' },
  { value: 'orders', label: 'Orders' },
  { value: 'accounts', label: 'Accounts' },
  { value: 'fleets', label: 'Fleets' },
  { value: 'drivers', label: 'Drivers' },
  { value: 'billings', label: 'Billings' },
  { value: 'invoices', label: 'Invoices' },
  { value: 'pods', label: 'PODs' },
];

export default function SearchBar({ onSearch, isLoading, placeholder }: SearchBarProps) {
  const [query, setQuery] = useState('');
  const [searchType, setSearchType] = useState<SearchType>('all');
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(-1);
  const inputRef = useRef<HTMLInputElement>(null);
  const suggestionsRef = useRef<HTMLDivElement>(null);

  const { suggestions, isLoading: loadingSuggestions } = useAutocomplete(query, searchType);

  useEffect(() => {
    // Close suggestions when clicking outside
    function handleClickOutside(event: MouseEvent) {
      if (
        suggestionsRef.current &&
        !suggestionsRef.current.contains(event.target as Node) &&
        !inputRef.current?.contains(event.target as Node)
      ) {
        setShowSuggestions(false);
      }
    }

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (query.trim()) {
      onSearch(query.trim(), searchType);
      setShowSuggestions(false);
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setQuery(e.target.value);
    setShowSuggestions(true);
    setSelectedIndex(-1);
  };

  const handleSuggestionClick = (suggestionText: string) => {
    setQuery(suggestionText);
    setShowSuggestions(false);
    onSearch(suggestionText, searchType);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (!showSuggestions || suggestions.length === 0) return;

    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        setSelectedIndex((prev) => (prev < suggestions.length - 1 ? prev + 1 : prev));
        break;
      case 'ArrowUp':
        e.preventDefault();
        setSelectedIndex((prev) => (prev > 0 ? prev - 1 : -1));
        break;
      case 'Enter':
        e.preventDefault();
        if (selectedIndex >= 0 && suggestions[selectedIndex]) {
          handleSuggestionClick(suggestions[selectedIndex].text);
        } else {
          handleSubmit(e);
        }
        break;
      case 'Escape':
        setShowSuggestions(false);
        setSelectedIndex(-1);
        break;
    }
  };

  const clearQuery = () => {
    setQuery('');
    setShowSuggestions(false);
    inputRef.current?.focus();
  };

  return (
    <div className="relative w-full max-w-4xl">
      <form onSubmit={handleSubmit} className="relative">
        <div className="flex gap-2">
          {/* Search Type Selector */}
          <select
            value={searchType}
            onChange={(e) => setSearchType(e.target.value as SearchType)}
            className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white text-sm"
          >
            {SEARCH_TYPES.map((type) => (
              <option key={type.value} value={type.value}>
                {type.label}
              </option>
            ))}
          </select>

          {/* Search Input */}
          <div className="flex-1 relative">
            <div className="relative">
              <FiSearch className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                ref={inputRef}
                type="text"
                value={query}
                onChange={handleInputChange}
                onKeyDown={handleKeyDown}
                onFocus={() => query && setShowSuggestions(true)}
                placeholder={placeholder || 'Search orders, accounts, vehicles, drivers...'}
                className="w-full pl-12 pr-12 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-gray-900"
              />
              {query && (
                <button
                  type="button"
                  onClick={clearQuery}
                  className="absolute right-4 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
                >
                  <FiX className="w-5 h-5" />
                </button>
              )}
            </div>

            {/* Autocomplete Suggestions */}
            {showSuggestions && suggestions.length > 0 && (
              <div
                ref={suggestionsRef}
                className="absolute z-10 w-full mt-2 bg-white rounded-lg shadow-lg border border-gray-200 max-h-80 overflow-y-auto"
              >
                {suggestions.map((suggestion, index) => (
                  <button
                    key={`${suggestion.metadata.id}-${index}`}
                    type="button"
                    onClick={() => handleSuggestionClick(suggestion.text)}
                    className={clsx(
                      'w-full px-4 py-3 text-left hover:bg-blue-50 border-b border-gray-100 last:border-b-0 transition-colors',
                      selectedIndex === index && 'bg-blue-50'
                    )}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex-1">
                        <div className="text-sm font-medium text-gray-900">
                          {suggestion.text}
                        </div>
                        <div className="text-xs text-gray-500 mt-1">
                          {suggestion.type} • {suggestion.collection}
                        </div>
                      </div>
                      <div className="ml-3 text-xs text-gray-400">
                        Score: {suggestion.score.toFixed(1)}
                      </div>
                    </div>
                  </button>
                ))}
              </div>
            )}

            {/* Loading Indicator */}
            {loadingSuggestions && query && (
              <div className="absolute right-14 top-1/2 transform -translate-y-1/2">
                <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-blue-500"></div>
              </div>
            )}
          </div>

          {/* Search Button */}
          <button
            type="submit"
            disabled={isLoading || !query.trim()}
            className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
          >
            {isLoading ? (
              <>
                <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
                <span>Searching...</span>
              </>
            ) : (
              <>
                <FiSearch className="w-5 h-5" />
                <span>Search</span>
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
