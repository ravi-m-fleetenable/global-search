import { useState, useCallback, useEffect } from 'react';
import { apiService } from '@/services/api';
import { AutocompleteSuggestion, SearchType } from '@/types';
import { useDebounce } from './useDebounce';

interface UseAutocompleteOptions {
  delay?: number;
  minChars?: number;
  limit?: number;
}

export function useAutocomplete(
  query: string,
  collection: SearchType,
  options: UseAutocompleteOptions = {}
) {
  const { delay = 300, minChars = 2, limit = 10 } = options;

  const [suggestions, setSuggestions] = useState<AutocompleteSuggestion[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const debouncedQuery = useDebounce(query, delay);

  const fetchSuggestions = useCallback(async () => {
    if (!debouncedQuery || debouncedQuery.length < minChars || collection === 'all') {
      setSuggestions([]);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const response = await apiService.autocomplete(debouncedQuery, collection, limit);
      setSuggestions(response.suggestions);
    } catch (err: any) {
      const errorMessage = err.response?.data?.error || 'Autocomplete failed';
      setError(errorMessage);
      setSuggestions([]);
    } finally {
      setIsLoading(false);
    }
  }, [debouncedQuery, collection, minChars, limit]);

  useEffect(() => {
    fetchSuggestions();
  }, [fetchSuggestions]);

  const clearSuggestions = useCallback(() => {
    setSuggestions([]);
  }, []);

  return {
    suggestions,
    isLoading,
    error,
    clearSuggestions,
  };
}
