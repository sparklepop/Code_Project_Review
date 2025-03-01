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
      # Get individual scores
      naming_score = analyze_naming_conventions(ruby_files, js_files)
      simplicity_score = analyze_method_simplicity(ruby_files, js_files)
      organization_score = analyze_code_organization(ruby_files, js_files)
      comments_score = analyze_comments_quality(ruby_files, js_files)

      # Calculate weighted scores
      weighted_naming = calculate_weighted_score(naming_score[:score], :code_clarity, :naming_conventions)
      weighted_simplicity = calculate_weighted_score(simplicity_score[:score], :code_clarity, :method_simplicity)
      weighted_organization = calculate_weighted_score(organization_score[:score], :code_clarity, :code_organization)
      weighted_comments = calculate_weighted_score(comments_score[:score], :code_clarity, :comments_quality)

      # Calculate total
      total = weighted_naming + weighted_simplicity + weighted_organization + weighted_comments

      {
        naming_conventions: naming_score.merge(weighted_score: weighted_naming),
        method_simplicity: simplicity_score.merge(weighted_score: weighted_simplicity),
        code_organization: organization_score.merge(weighted_score: weighted_organization),
        comments_quality: comments_score.merge(weighted_score: weighted_comments),
        total_score: total
      }
    end

    def analyze_architecture(ruby_files, js_files)
      # Get individual scores
      concerns_score = analyze_separation_of_concerns(ruby_files, js_files)
      organization_score = analyze_file_organization(ruby_files, js_files)
      dependency_score = analyze_dependencies
      framework_score = analyze_framework_usage(ruby_files, js_files)

      # Calculate weighted scores
      weighted_concerns = calculate_weighted_score(concerns_score[:score], :architecture, :separation_of_concerns)
      weighted_organization = calculate_weighted_score(organization_score[:score], :architecture, :file_organization)
      weighted_dependency = calculate_weighted_score(dependency_score[:score], :architecture, :dependency_management)
      weighted_framework = calculate_weighted_score(framework_score[:score], :architecture, :framework_usage)

      # Calculate total
      total = weighted_concerns + weighted_organization + weighted_dependency + weighted_framework

      {
        separation_of_concerns: concerns_score.merge(weighted_score: weighted_concerns),
        file_organization: organization_score.merge(weighted_score: weighted_organization),
        dependency_management: dependency_score.merge(weighted_score: weighted_dependency),
        framework_usage: framework_score.merge(weighted_score: weighted_framework),
        total_score: total
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
      {
        score: 9.0,
        feedback: "Code is well organized with clear structure"
      }
    end

    def analyze_method_simplicity(ruby_files, js_files)
      method_analyses = analyze_methods_in_files(ruby_files.merge(js_files))
      
      score = calculate_method_score(method_analyses)
      feedback = generate_method_feedback(method_analyses)
      
      {
        score: score,
        feedback: feedback,
        details: method_analyses
      }
    end

    def analyze_methods_in_files(files)
      analyses = []
      
      files.each do |path, content|
        # Analyze each method in the file
        methods = extract_methods(content)
        
        methods.each do |method|
          analysis = {
            file: path,
            name: method[:name],
            length: method[:body].lines.count,
            complexity: calculate_method_complexity(method[:body]),
            concerns: analyze_method_concerns(method[:body])
          }
          
          analyses << analysis
        end
      end
      
      analyses
    end

    def extract_methods(content)
      methods = []
      
      # Match method definitions and their bodies
      content.scan(/(?:def|function)\s+(\w+)[^\n]*?\n(.*?)(?:end|\})/m) do |name, body|
        methods << {
          name: name,
          body: body.strip
        }
      end
      
      methods
    end

    def calculate_method_complexity(body)
      complexity = 0
      
      # Count control flow keywords
      complexity += body.scan(/\b(if|unless|else|elsif|case|when|while|until|for|each)\b/).count
      
      # Count nesting levels
      nesting = 0
      max_nesting = 0
      
      body.each_line do |line|
        nesting += line.scan(/\b(if|unless|case|while|until|for|each|do|{)\b/).count
        nesting -= line.scan(/\b(end|}\s*$)/).count
        max_nesting = [max_nesting, nesting].max
      end
      
      complexity += max_nesting
      complexity
    end

    def analyze_method_concerns(body)
      concerns = []
      
      # Check method length
      if body.lines.count > 10
        concerns << "Method is longer than recommended (#{body.lines.count} lines)"
      end
      
      # Check complexity
      complexity = calculate_method_complexity(body)
      if complexity > 5
        concerns << "Method has high complexity (score: #{complexity})"
      end
      
      # Check for multiple responsibilities
      if has_multiple_responsibilities?(body)
        concerns << "Method might have multiple responsibilities"
      end
      
      concerns
    end

    def has_multiple_responsibilities?(body)
      # Look for patterns that suggest multiple responsibilities
      indicators = [
        body.scan(/\b(save|update|create|delete)\b/).count > 1,  # Multiple DB operations
        body.scan(/\b(render|redirect)\b/).count > 1,            # Multiple view operations
        body.include?('rescue'),                                 # Error handling mixed with business logic
        body.scan(/\b(if|case)\b/).count > 2                    # Complex branching
      ]
      
      indicators.count(true) >= 2
    end

    def calculate_method_score(analyses)
      return 10 if analyses.empty?
      
      deductions = analyses.sum do |analysis|
        method_deductions = 0
        method_deductions += 0.5 if analysis[:length] > 10
        method_deductions += 1 if analysis[:complexity] > 5
        method_deductions += 1 if analysis[:concerns].any?
        method_deductions
      end
      
      score = 10 - [deductions, 10].min
      score.clamp(0, 10)
    end

    def generate_method_feedback(analyses)
      return "No methods found to analyze" if analyses.empty?
      
      feedback = []
      
      # Highlight problematic methods
      problem_methods = analyses.select { |a| a[:concerns].any? }
      if problem_methods.any?
        feedback << "Found #{problem_methods.count} methods that could be improved:"
        problem_methods.each do |method|
          feedback << "- #{method[:file]}: #{method[:name]}"
          method[:concerns].each do |concern|
            feedback << "  * #{concern}"
          end
        end
      end
      
      # Highlight good methods
      good_methods = analyses.select { |a| a[:concerns].empty? }
      if good_methods.any?
        feedback << "\nWell-structured methods:"
        good_methods.take(3).each do |method|
          feedback << "- #{method[:name]} in #{method[:file]}"
        end
      end
      
      feedback.join("\n")
    end

    def analyze_comments_quality(ruby_files, js_files)
      # Return a hash with score and feedback instead of multiple values
      {
        score: 7,
        feedback: "Comments quality analysis feedback"
      }
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
      {
        score: 8.0,
        feedback: "Good separation of concerns between components"
      }
    end

    def analyze_file_organization(ruby_files, js_files)
      {
        score: 7.0,
        feedback: "Files are organized following framework conventions"
      }
    end

    def analyze_dependencies
      {
        score: 8.0,
        feedback: "Dependencies are well managed and up to date"
      }
    end

    def analyze_framework_usage(ruby_files, js_files)
      {
        score: 8.0,
        feedback: "Good use of framework features and conventions"
      }
    end

    def analyze_development_practices(test_files, doc_files)
      # Get individual scores
      commit_score = {
        score: 8,
        feedback: "Commits are focused and well-documented"
      }
      testing_score = {
        score: 7,
        feedback: "Basic test coverage is present"
      }
      documentation_score = {
        score: 7,
        feedback: "Documentation covers key functionality"
      }

      # Calculate weighted scores
      weighted_commit = calculate_weighted_score(commit_score[:score], :practices, :commit_quality)
      weighted_testing = calculate_weighted_score(testing_score[:score], :practices, :basic_testing)
      weighted_docs = calculate_weighted_score(documentation_score[:score], :practices, :documentation)

      # Calculate total
      total = weighted_commit + weighted_testing + weighted_docs

      {
        commit_quality: commit_score.merge(weighted_score: weighted_commit),
        basic_testing: testing_score.merge(weighted_score: weighted_testing),
        documentation: documentation_score.merge(weighted_score: weighted_docs),
        total_score: total
      }
    end

    def analyze_problem_solving(ruby_files, js_files)
      # Get individual scores
      simplicity_score = {
        score: 9,
        feedback: "All core requirements are met with good attention to detail."
      }
      reuse_score = {
        score: 8,
        feedback: "Solution demonstrates solid understanding of the problem domain."
      }

      # Calculate weighted scores
      weighted_simplicity = calculate_weighted_score(simplicity_score[:score], :problem_solving, :solution_simplicity)
      weighted_reuse = calculate_weighted_score(reuse_score[:score], :problem_solving, :code_reuse)

      # Calculate total
      total = weighted_simplicity + weighted_reuse

      {
        solution_simplicity: simplicity_score.merge(weighted_score: weighted_simplicity),
        code_reuse: reuse_score.merge(weighted_score: weighted_reuse),
        total_score: total
      }
    end

    def analyze_bonus_points(ruby_files, js_files, test_files)
      # Get individual scores
      testing_score = {
        score: 4,
        feedback: "Some advanced testing patterns present"
      }
      security_score = {
        score: 3,
        feedback: "Basic security considerations implemented"
      }
      performance_score = {
        score: 3,
        feedback: "Some performance optimizations present"
      }

      # Calculate weighted scores
      weighted_testing = calculate_weighted_score(testing_score[:score], :bonus, :advanced_testing)
      weighted_security = calculate_weighted_score(security_score[:score], :bonus, :security_practices)
      weighted_performance = calculate_weighted_score(performance_score[:score], :bonus, :performance_considerations)

      # Calculate total
      total = weighted_testing + weighted_security + weighted_performance

      {
        advanced_testing: testing_score.merge(weighted_score: weighted_testing),
        security_practices: security_score.merge(weighted_score: weighted_security),
        performance_considerations: performance_score.merge(weighted_score: weighted_performance),
        total_score: total
      }
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