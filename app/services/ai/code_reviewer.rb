module Ai
  class CodeReviewer
    include CodeAnalysisHelpers

    def initialize(submission_url)
      @submission_url = submission_url
      @repo_content = fetch_repository_content
    end

    def analyze
      Rails.logger.debug "Starting code analysis..."
      
      @languages = LanguageDetector.detect_languages(@repo_content)
      Rails.logger.debug "Detected languages: #{@languages.join(', ')}"

      results = {
        quality_scores: analyze_code_quality,
        documentation_scores: analyze_documentation,
        technical_scores: analyze_technical_implementation,
        problem_solving_scores: analyze_problem_solving,
        testing_scores: analyze_testing,
        overall_comments: generate_overall_comments,
        languages: @languages
      }

      Rails.logger.debug "Analysis results: #{results.inspect}"
      results
    end

    private

    def fetch_repository_content
      fetcher = Github::RepositoryFetcher.new(@submission_url)
      fetcher.fetch
    rescue Github::GithubError => e
      Rails.logger.error("Repository fetch failed: #{e.message}")
      {}
    end

    def analyze_code_quality
      # Group files by language
      files_by_language = @repo_content.group_by do |path, _|
        LanguageDetector.language_from_path(path)
      end

      # Analyze each language with appropriate analyzer
      clarity_scores = []
      naming_scores = []
      organization_scores = []

      files_by_language.each do |language, files|
        next unless language # Skip unknown languages
        
        analyzer = code_analyzer_for(language)
        results = analyzer.analyze(files)
        
        clarity_scores << results.clarity_score
        naming_scores << results.naming_score
        organization_scores << results.organization_score
        
        @clarity_reasons ||= []
        @clarity_reasons.concat(results.clarity_reasons)
      end

      {
        code_clarity: average_score(clarity_scores),
        code_clarity_reason: @clarity_reasons,
        naming_conventions: average_score(naming_scores),
        naming_conventions_reason: @naming_reasons,
        code_organization: average_score(organization_scores),
        code_organization_reason: @organization_reasons
      }
    end

    def code_analyzer_for(language)
      case language
      when :ruby
        RubyAnalyzer.new
      when :javascript
        JavaScriptAnalyzer.new
      when :python
        PythonAnalyzer.new
      # Add more languages as needed
      else
        GenericAnalyzer.new
      end
    end

    def average_score(scores)
      return 0 if scores.empty?
      (scores.sum.to_f / scores.size).round
    end

    def analyze_code_clarity(files)
      @clarity_reasons = []
      
      files.each do |path, file|
        # Analyze method lengths
        analyze_method_lengths(path, file[:content])
        # Check method complexity
        analyze_method_complexity(path, file[:content])
        # Evaluate single responsibility
        analyze_single_responsibility(path, file[:content])
      end

      calculate_clarity_score
    end

    def analyze_naming_conventions(files)
      # Implement naming conventions analysis
      8 # Placeholder score
    end

    def analyze_code_organization(files)
      # Implement code organization analysis
      9 # Placeholder score
    end

    def analyze_setup_instructions
      7 # Sample score out of 8
    end

    def analyze_technical_decisions
      6 # Sample score out of 7
    end

    def analyze_assumptions
      4 # Sample score out of 5
    end

    def analyze_solution_correctness
      13 # Sample score out of 15
    end

    def analyze_error_handling
      4 # Sample score out of 5
    end

    def analyze_language_usage
      4 # Sample score out of 5
    end

    def analyze_completeness
      9 # Sample score out of 10
    end

    def analyze_approach
      8 # Sample score out of 10
    end

    def analyze_test_coverage
      6 # Sample score out of 7
    end

    def analyze_test_quality
      4 # Sample score out of 5
    end

    def analyze_edge_cases
      2 # Sample score out of 3
    end

    def generate_overall_comments
      scores = {
        quality_total: 29,
        quality_comments: "Good naming conventions and organization, with clear code structure.",
        documentation_total: 17,
        documentation_comments: "Well-documented setup instructions and technical decisions.",
        technical_total: 21,
        technical_comments: "Strong solution correctness with adequate error handling.",
        problem_solving_total: 17,
        problem_solving_comments: "Complete solution with a solid approach.",
        testing_total: 12,
        testing_comments: "Good test coverage with some edge cases covered."
      }

      format_overall_comments(scores)
    end

    def format_overall_comments(scores)
      comments = []
      
      comments << "Code Quality (#{scores[:quality_total]}/35): #{scores[:quality_comments]}"
      comments << "Documentation (#{scores[:documentation_total]}/20): #{scores[:documentation_comments]}"
      comments << "Technical Implementation (#{scores[:technical_total]}/25): #{scores[:technical_comments]}"
      comments << "Problem Solving (#{scores[:problem_solving_total]}/20): #{scores[:problem_solving_comments]}"
      comments << "Testing Bonus (#{scores[:testing_total]}/15): #{scores[:testing_comments]}"
      
      comments.join("\n\n")
    end

    def calculate_clarity_score
      # TODO: Implement actual analysis
      12 # Placeholder score
    end

    def analyze_documentation
      {
        setup_instructions: 7,
        setup_instructions_reason: "README includes clear setup steps but missing environment requirements.",
        technical_decisions: 6,
        technical_decisions_reason: "Key architectural decisions are documented in comments, but rationale could be more detailed.",
        assumptions: 4,
        assumptions_reason: "Core assumptions about data structure are documented inline."
      }
    end

    def analyze_technical_implementation
      {
        solution_correctness: 13,
        solution_correctness_reason: "Core functionality works as expected with good edge case handling.",
        error_handling: 4,
        error_handling_reason: "Basic error cases are handled, but could use more robust validation.",
        language_usage: 4,
        language_usage_reason: "Good use of Ruby idioms, though some modern features could be utilized better."
      }
    end

    def analyze_problem_solving
      {
        completeness: 9,
        completeness_reason: "All core requirements are met with good attention to detail.",
        approach: 8,
        approach_reason: "Solution demonstrates solid understanding of the problem domain."
      }
    end

    def analyze_testing
      {
        coverage: 6,
        coverage_reason: "Good coverage of core functionality, some edge cases missing.",
        quality: 4,
        quality_reason: "Tests are well-organized but could use more descriptive contexts.",
        edge_cases: 2,
        edge_cases_reason: "Basic edge cases covered, but missing some important scenarios."
      }
    end
  end
end 