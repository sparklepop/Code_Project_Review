# frozen_string_literal: true

require_relative 'code_analyzer'

puts "Loading CodeReviewer..."

module Ai
  class CodeReviewer
    def initialize(submission_url)
      Rails.logger.debug "Initializing CodeReviewer with URL: #{submission_url}"
      @submission_url = submission_url
      @repo_content = fetch_repository_content
    end

    def analyze
      Rails.logger.debug "Starting code analysis..."
      
      source_analysis = Ai::CodeAnalyzer.new(@repo_content[:source_files]).analyze
      test_analysis = Ai::CodeAnalyzer.new(@repo_content[:test_files]).analyze

      {
        quality_scores: source_analysis[:quality_scores],
        documentation_scores: source_analysis[:documentation_scores],
        technical_scores: source_analysis[:technical_scores],
        problem_solving_scores: source_analysis[:problem_solving_scores],
        testing_scores: test_analysis[:testing_scores],
        issues: {
          source: source_analysis[:issues],
          test: test_analysis[:issues]
        }
      }
    end

    private

    def fetch_repository_content
      fetcher = Github::RepositoryFetcher.new(@submission_url)
      fetcher.fetch
    rescue Github::GithubError => e
      Rails.logger.error("Repository fetch failed: #{e.message}")
      { source_files: {}, test_files: {} }
    end
  end
end 