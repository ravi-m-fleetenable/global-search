module Search
  class FuzzySearchService
    attr_reader :query_text, :max_edits, :prefix_length

    def initialize(query_text, options = {})
      @query_text = query_text
      @max_edits = options.fetch(:max_edits, 2)
      @prefix_length = options.fetch(:prefix_length, 0)
    end

    # Calculate Levenshtein distance between two strings
    def self.levenshtein_distance(str1, str2)
      str1 = str1.to_s.downcase
      str2 = str2.to_s.downcase

      matrix = Array.new(str1.length + 1) { Array.new(str2.length + 1) }

      (0..str1.length).each { |i| matrix[i][0] = i }
      (0..str2.length).each { |j| matrix[0][j] = j }

      (1..str1.length).each do |i|
        (1..str2.length).each do |j|
          cost = str1[i - 1] == str2[j - 1] ? 0 : 1
          matrix[i][j] = [
            matrix[i - 1][j] + 1,      # deletion
            matrix[i][j - 1] + 1,      # insertion
            matrix[i - 1][j - 1] + cost # substitution
          ].min
        end
      end

      matrix[str1.length][str2.length]
    end

    # Check if two strings are within the fuzzy threshold
    def self.fuzzy_match?(str1, str2, max_distance = 2)
      levenshtein_distance(str1, str2) <= max_distance
    end

    # Calculate similarity score (0-100)
    def self.similarity_score(str1, str2)
      str1 = str1.to_s
      str2 = str2.to_s
      max_length = [str1.length, str2.length].max
      return 100 if max_length.zero?

      distance = levenshtein_distance(str1, str2)
      ((1 - distance.to_f / max_length) * 100).round(2)
    end

    # Build fuzzy search configuration for Atlas Search
    def fuzzy_config
      {
        'maxEdits' => max_edits,
        'prefixLength' => prefix_length,
        'maxExpansions' => 50
      }
    end

    # Filter and rank results by fuzzy matching
    def filter_and_rank(results, field_name, threshold: 70)
      results.map do |result|
        field_value = result[field_name].to_s
        score = self.class.similarity_score(query_text, field_value)

        next if score < threshold

        {
          result: result,
          fuzzy_score: score,
          distance: self.class.levenshtein_distance(query_text, field_value)
        }
      end.compact.sort_by { |r| -r[:fuzzy_score] }
    end

    # Generate suggestions based on fuzzy matching
    def generate_suggestions(candidates, max_suggestions: 5, threshold: 60)
      scored = candidates.map do |candidate|
        score = self.class.similarity_score(query_text, candidate)
        next if score < threshold

        {
          text: candidate,
          score: score,
          distance: self.class.levenshtein_distance(query_text, candidate)
        }
      end.compact

      scored.sort_by { |s| [-s[:score], s[:distance]] }.take(max_suggestions)
    end
  end
end
