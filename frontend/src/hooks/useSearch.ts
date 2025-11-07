import { useState, useCallback } from 'react';
import { apiService } from '@/services/api';
import { SearchRequest, SearchResponse, SearchType } from '@/types';
import { toast } from 'react-toastify';

export function useSearch() {
  const [results, setResults] = useState<SearchResponse | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const search = useCallback(async (params: SearchRequest) => {
    setIsLoading(true);
    setError(null);

    try {
      const response = await apiService.globalSearch(params);
      setResults(response);
      return response;
    } catch (err: any) {
      const errorMessage = err.response?.data?.error || 'Search failed';
      setError(errorMessage);
      toast.error(errorMessage);
      return null;
    } finally {
      setIsLoading(false);
    }
  }, []);

  const clearResults = useCallback(() => {
    setResults(null);
    setError(null);
  }, []);

  return {
    results,
    isLoading,
    error,
    search,
    clearResults,
  };
}
