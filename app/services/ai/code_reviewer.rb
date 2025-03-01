module Ai
  class CodeReviewer
    SCORE_WEIGHTS = {
      code_clarity: 35,
      architecture: 25,
      practices: 25,
      problem_solving: 15,
      bonus: 15
    }.freeze

    CLARITY_WEIGHTS = {
      naming_conventions: 10,
      method_simplicity: 10,
      code_organization: 10,
      comments_quality: 5
    }.freeze

    ARCHITECTURE_WEIGHTS = {
      separation_of_concerns: 10,
      file_organization: 5,
      dependency_management: 5,
      framework_usage: 5
    }.freeze

    PRACTICES_WEIGHTS = {
      commit_quality: 10,
      basic_testing: 10,
      documentation: 5
    }.freeze

    PROBLEM_SOLVING_WEIGHTS = {
      solution_simplicity: 10,
      code_reuse: 5
    }.freeze

    BONUS_WEIGHTS = {
      advanced_testing: 5,
      security_practices: 5,
      performance_considerations: 5
    }.freeze

    def initialize(repo_path)
      @repo_path = repo_path
      @files = load_repository_files
      Rails.logger.debug "Loaded #{@files.count} files for analysis"
    end

    def analyze
      Rails.logger.debug "Starting code analysis..."
      
      # Group files by type for analysis
      ruby_files = @files.select { |path, _| path.end_with?('.rb') }
      js_files = @files.select { |path, _| path.end_with?('.js', '.ts') }
      test_files = @files.select { |path, _| path.include?('test/') || path.include?('spec/') }
      doc_files = @files.select { |path, _| path.end_with?('.md', '.rdoc') }
      
      results = {
        clarity_scores: analyze_code_clarity(ruby_files, js_files),
        architecture_scores: analyze_architecture(ruby_files, js_files),
        practices_scores: analyze_development_practices(test_files, doc_files),
        problem_solving_scores: analyze_problem_solving(ruby_files, js_files),
        bonus_scores: analyze_bonus_points(ruby_files, js_files, test_files)
      }

      Rails.logger.debug "Analysis complete: #{results.inspect}"
      results
    end

    private

    def load_repository_files
      files = {}
      Dir.glob("#{@repo_path}/**/*").each do |file|
        next unless File.file?(file)
        next if file.include?('.git/')
        
        relative_path = file.sub("#{@repo_path}/", '')
        files[relative_path] = File.read(file)
      end
      
      Rails.logger.debug "Loaded #{files.count} files for analysis"
      files
    rescue => e
      Rails.logger.error "Error loading repository files: #{e.message}"
      {}
    end

    def analyze_code_clarity(ruby_files, js_files)
      # Analyze naming conventions (10 points)
      naming_results = analyze_naming_conventions(ruby_files, js_files)
      
      # Analyze method simplicity (10 points)
      simplicity_results = analyze_method_simplicity(ruby_files, js_files)
      
      # Analyze code organization (10 points)
      organization_results = analyze_code_organization(ruby_files, js_files)
      
      # Analyze comments quality (5 points)
      comments_results = analyze_comments_quality(ruby_files, js_files)

      {
        naming_conventions: naming_results,
        method_simplicity: simplicity_results,
        code_organization: organization_results,
        comments_quality: comments_results,
        total_score: calculate_category_score([
          naming_results,
          simplicity_results,
          organization_results,
          comments_results
        ])
      }
    end

    def analyze_architecture(ruby_files, js_files)
      # Analyze separation of concerns (10 points)
      concerns_results = analyze_separation_of_concerns(ruby_files, js_files)
      
      # Analyze file organization (5 points)
      organization_results = analyze_file_organization(ruby_files, js_files)
      
      # Analyze dependency management (5 points)
      dependency_results = analyze_dependencies
      
      # Analyze framework usage (5 points)
      framework_results = analyze_framework_usage(ruby_files, js_files)

      {
        separation_of_concerns: concerns_results,
        file_organization: organization_results,
        dependency_management: dependency_results,
        framework_usage: framework_results,
        total_score: calculate_category_score([
          concerns_results,
          organization_results,
          dependency_results,
          framework_results
        ])
      }
    end

    def analyze_naming_conventions(ruby_files, js_files)
      issues = []
      good_examples = []

      files_to_analyze = ruby_files.merge(js_files)
      files_to_analyze.each do |path, content|
        analyze_file_naming(path, content, issues, good_examples)
      end

      score = calculate_naming_score(issues)
      {
        score: score,
        feedback: generate_naming_feedback(issues, good_examples),
        details: {
          issues: issues,
          good_examples: good_examples
        }
      }
    end

    def analyze_file_naming(path, content, issues, good_examples)
      # I can analyze the content and provide specific feedback
      content.scan(/\b(def|class|module|var|let|const)\s+([a-zA-Z_]\w*)/).each do |type, name|
        if good_name?(name, type)
          good_examples << { type: type, name: name, file: path }
        else
          issues << { type: type, name: name, file: path, suggestion: suggest_better_name(name, type) }
        end
      end
    end

    def analyze_code_organization(ruby_files, js_files)
      9 # Sample score out of 10
    end

    def analyze_method_simplicity(ruby_files, js_files)
      # Implementation of analyze_method_simplicity method
      # This method should return two values: simplicity_score and simplicity_feedback
      8, "Method simplicity analysis feedback" # Placeholder values
    end

    def analyze_comments_quality(ruby_files, js_files)
      # Implementation of analyze_comments_quality method
      # This method should return two values: comments_score and comments_feedback
      7, "Comments quality analysis feedback" # Placeholder values
    end

    def calculate_naming_score(issues)
      # Implementation of calculate_naming_score method
      # This method should return a score based on the number of issues
      8 # Placeholder score
    end

    def generate_naming_feedback(issues, good_examples)
      # Implementation of generate_naming_feedback method
      # This method should return a string of feedback based on the issues and good_examples
      "Good naming practices found in the following files: #{good_examples.map { |e| e[:file] }.join(', ')}"
    end

    def suggest_better_name(name, type)
      # Implementation of suggest_better_name method
      # This method should return a suggested better name for the given name and type
      "Better_#{name}_#{type}" # Placeholder suggestion
    end

    def good_name?(name, type)
      # Implementation of good_name? method
      # This method should return true if the name is considered good, false otherwise
      true # Placeholder implementation
    end

    def analyze_separation_of_concerns(ruby_files, js_files)
      # Implementation of analyze_separation_of_concerns method
      # This method should return a hash with separation of concerns analysis results
      {
        # Placeholder keys and values
      }
    end

    def analyze_file_organization(ruby_files, js_files)
      # Implementation of analyze_file_organization method
      # This method should return a hash with file organization analysis results
      {
        # Placeholder keys and values
      }
    end

    def analyze_dependencies
      # Implementation of analyze_dependencies method
      # This method should return a hash with dependency management analysis results
      {
        # Placeholder keys and values
      }
    end

    def analyze_framework_usage(ruby_files, js_files)
      # Implementation of analyze_framework_usage method
      # This method should return a hash with framework usage analysis results
      {
        # Placeholder keys and values
      }
    end

    def analyze_development_practices(test_files, doc_files)
      # Implementation of analyze_development_practices method
      # This method should return a hash with development practices analysis results
      {
        # Placeholder keys and values
      }
    end

    def analyze_problem_solving(ruby_files, js_files)
      {
        completeness: 9,
        completeness_reason: "All core requirements are met with good attention to detail.",
        approach: 8,
        approach_reason: "Solution demonstrates solid understanding of the problem domain."
      }
    end

    def analyze_bonus_points(ruby_files, js_files, test_files)
      # Implementation of analyze_bonus_points method
      # This method should return a hash with bonus points analysis results
      {
        # Placeholder keys and values
      }
    end

    def calculate_category_score(results)
      results.sum { |r| r[:score] }
    end

    def calculate_weighted_score(score, category, subcategory)
      max_score = case category
      when :code_clarity
        CLARITY_WEIGHTS[subcategory]
      when :architecture
        ARCHITECTURE_WEIGHTS[subcategory]
      when :practices
        PRACTICES_WEIGHTS[subcategory]
      when :problem_solving
        PROBLEM_SOLVING_WEIGHTS[subcategory]
      when :bonus
        BONUS_WEIGHTS[subcategory]
      end

      (score.to_f / 10 * max_score).round(1)
    end
  end
end 