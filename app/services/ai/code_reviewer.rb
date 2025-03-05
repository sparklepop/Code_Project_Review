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

    def analyze_separation_of_concerns(ruby_files, js_files)
      issues = []
      good_examples = []
      
      # Initialize metrics
      class_metrics = {}
      controller_metrics = {}
      model_metrics = {}
      service_metrics = {}
      
      # Analyze Ruby files
      ruby_files.each do |path, content|
        if path.include?('app/controllers/')
          analyze_controller(path, content, controller_metrics, issues, good_examples)
        elsif path.include?('app/models/')
          analyze_model(path, content, model_metrics, issues, good_examples)
        elsif path.include?('app/services/')
          analyze_service(path, content, service_metrics, issues, good_examples)
        end
        
        # General class analysis
        analyze_class_structure(path, content, class_metrics, issues, good_examples)
      end
      
      # Analyze JavaScript/TypeScript files
      js_files.each do |path, content|
        analyze_js_component(path, content, class_metrics, issues, good_examples)
      end
      
      # Calculate base score
      score = 10.0
      
      # Analyze controller metrics
      if controller_metrics.any?
        avg_controller_actions = controller_metrics.values.map { |m| m[:action_count] }.sum.to_f / controller_metrics.size
        if avg_controller_actions > 7
          score -= 1
          issues << { general: "Controllers average #{avg_controller_actions.round(1)} actions. Consider breaking down large controllers." }
        end
        
        fat_controllers = controller_metrics.select { |_, m| m[:lines_of_business_logic] > 50 }
        if fat_controllers.any?
          score -= 1
          issues << { general: "Found #{fat_controllers.size} controllers with excessive business logic. Move logic to models or services." }
        end
      end
      
      # Analyze model metrics
      if model_metrics.any?
        fat_models = model_metrics.select { |_, m| m[:instance_method_count] > 15 }
        if fat_models.any?
          score -= 1
          issues << { general: "Found #{fat_models.size} models with too many instance methods. Consider extracting concerns or creating service objects." }
        end
      end
      
      # Analyze class coupling
      high_coupling = class_metrics.select { |_, m| m[:dependency_count] > 5 }
      if high_coupling.any?
        score -= 1
        issues << { general: "Found #{high_coupling.size} classes with high coupling (>5 dependencies). Consider reducing dependencies." }
      end
      
      # Check service object usage
      if service_metrics.empty? && (controller_metrics.any? || model_metrics.any?)
        score -= 0.5
        issues << { general: "No service objects found. Consider using service objects for complex business logic." }
      end
      
      # Generate feedback
      feedback = generate_separation_feedback(issues, good_examples, {
        controllers: controller_metrics,
        models: model_metrics,
        services: service_metrics,
        classes: class_metrics
      })
      
      {
        score: score.clamp(0, 10),
        feedback: feedback,
        details: {
          issues: issues,
          good_examples: good_examples,
          metrics: {
            controller_count: controller_metrics.size,
            model_count: model_metrics.size,
            service_count: service_metrics.size,
            high_coupling_count: high_coupling.size
          }
        }
      }
    end

    def analyze_controller(path, content, metrics, issues, good_examples)
      class_name = File.basename(path, '.rb').camelize
      
      metrics[class_name] = {
        action_count: 0,
        lines_of_business_logic: 0,
        before_actions: 0
      }
      
      # Count actions
      action_methods = content.scan(/def\s+(index|show|new|create|edit|update|destroy|\w+)/).flatten
      metrics[class_name][:action_count] = action_methods.size
      
      # Count before_actions
      before_actions = content.scan(/before_action/).size
      metrics[class_name][:before_actions] = before_actions
      
      # Analyze action complexity
      content.split("\n").each do |line|
        # Count lines that appear to be business logic
        if line.match?(/\b(where|find_by|order|includes|joins|select|group|having)\b/) ||
           line.match?(/\b(create|update|destroy|save|transaction)\b/)
          metrics[class_name][:lines_of_business_logic] += 1
        end
      end
      
      # Check for fat controller anti-pattern
      if metrics[class_name][:lines_of_business_logic] > 50
        issues << {
          file: path,
          class: class_name,
          issue: "Controller has #{metrics[class_name][:lines_of_business_logic]} lines of business logic. Consider moving logic to models or services."
        }
      end
      
      # Identify good practices
      if metrics[class_name][:action_count] <= 7 && metrics[class_name][:lines_of_business_logic] < 30
        good_examples << {
          file: path,
          class: class_name,
          note: "Well-structured controller with focused responsibilities"
        }
      end
    end

    def analyze_model(path, content, metrics, issues, good_examples)
      class_name = File.basename(path, '.rb').camelize
      
      metrics[class_name] = {
        instance_method_count: 0,
        class_method_count: 0,
        association_count: 0,
        callback_count: 0,
        validation_count: 0
      }
      
      # Count instance methods
      instance_methods = content.scan(/def\s+(?!self\.)(\w+)/).flatten
      metrics[class_name][:instance_method_count] = instance_methods.size
      
      # Count class methods
      class_methods = content.scan(/def\s+self\.(\w+)/).flatten
      metrics[class_name][:class_method_count] = class_methods.size
      
      # Count associations
      associations = content.scan(/\b(belongs_to|has_many|has_one|has_and_belongs_to_many)\b/).flatten
      metrics[class_name][:association_count] = associations.size
      
      # Count callbacks
      callbacks = content.scan(/\b(before_save|after_save|before_create|after_create|before_update|after_update)\b/).flatten
      metrics[class_name][:callback_count] = callbacks.size
      
      # Count validations
      validations = content.scan(/\b(validates|validate|validates_presence_of|validates_uniqueness_of)\b/).flatten
      metrics[class_name][:validation_count] = validations.size
      
      # Check for fat model anti-pattern
      if metrics[class_name][:instance_method_count] > 15
        issues << {
          file: path,
          class: class_name,
          issue: "Model has #{metrics[class_name][:instance_method_count]} instance methods. Consider extracting concerns or creating service objects."
        }
      end
      
      # Check for callback complexity
      if metrics[class_name][:callback_count] > 3
        issues << {
          file: path,
          class: class_name,
          issue: "Model has #{metrics[class_name][:callback_count]} callbacks. Consider moving complex callbacks to service objects."
        }
      end
      
      # Identify good practices
      if metrics[class_name][:instance_method_count] <= 15 && 
         metrics[class_name][:callback_count] <= 3 &&
         metrics[class_name][:validation_count] > 0
        good_examples << {
          file: path,
          class: class_name,
          note: "Well-structured model with appropriate validations and manageable complexity"
        }
      end
    end

    def analyze_service(path, content, metrics, issues, good_examples)
      class_name = File.basename(path, '.rb').camelize
      
      metrics[class_name] = {
        public_method_count: 0,
        private_method_count: 0,
        dependency_count: 0,
        responsibility_focus: :single # or :multiple
      }
      
      # Count public methods
      public_methods = content.scan(/def\s+(?!private|protected)(\w+)/).flatten
      metrics[class_name][:public_method_count] = public_methods.size
      
      # Count private methods
      private_methods = content.scan(/private\s+def\s+(\w+)/).flatten
      metrics[class_name][:private_method_count] = private_methods.size
      
      # Count dependencies (class references)
      dependencies = content.scan(/\b[A-Z]\w+\b/).uniq
      metrics[class_name][:dependency_count] = dependencies.size
      
      # Analyze service focus
      if public_methods.size > 2 || content.include?('include') || content.include?('extend')
        metrics[class_name][:responsibility_focus] = :multiple
      end
      
      # Check for service object best practices
      if metrics[class_name][:public_method_count] > 2
        issues << {
          file: path,
          class: class_name,
          issue: "Service has #{metrics[class_name][:public_method_count]} public methods. Consider breaking into smaller, focused services."
        }
      end
      
      # Identify good practices
      if metrics[class_name][:public_method_count] <= 2 && 
         metrics[class_name][:responsibility_focus] == :single
        good_examples << {
          file: path,
          class: class_name,
          note: "Well-structured service with single responsibility"
        }
      end
    end

    def analyze_class_structure(path, content, metrics, issues, good_examples)
      class_name = File.basename(path, '.rb').camelize
      
      metrics[class_name] = {
        method_count: 0,
        dependency_count: 0,
        inheritance_depth: 0,
        mixin_count: 0
      }
      
      # Count methods
      methods = content.scan(/def\s+(\w+)/).flatten
      metrics[class_name][:method_count] = methods.size
      
      # Count dependencies
      dependencies = content.scan(/\b[A-Z]\w+\b/).uniq
      metrics[class_name][:dependency_count] = dependencies.size
      
      # Check inheritance depth
      inheritance_match = content.match(/class\s+\w+\s+<\s+(\w+)/)
      if inheritance_match
        metrics[class_name][:inheritance_depth] = 1
        parent = inheritance_match[1]
        if parent != 'ApplicationRecord' && parent != 'ApplicationController'
          issues << {
            file: path,
            class: class_name,
            issue: "Deep inheritance hierarchy. Consider using composition over inheritance."
          }
        end
      end
      
      # Count mixins
      mixins = content.scan(/\b(include|extend)\s+(\w+)/).flatten
      metrics[class_name][:mixin_count] = mixins.size
      
      # Check for high coupling
      if metrics[class_name][:dependency_count] > 5
        issues << {
          file: path,
          class: class_name,
          issue: "High coupling with #{metrics[class_name][:dependency_count]} dependencies. Consider reducing dependencies."
        }
      end
    end

    def analyze_js_component(path, content, metrics, issues, good_examples)
      component_name = File.basename(path, File.extname(path))
      
      metrics[component_name] = {
        method_count: 0,
        prop_count: 0,
        state_count: 0,
        effect_count: 0
      }
      
      # Count methods/functions
      methods = content.scan(/(?:function|const)\s+(\w+)\s*=?\s*(?:function|\(.*\)\s*=>)/).flatten
      metrics[component_name][:method_count] = methods.size
      
      # Count props (React)
      if content.include?('props') || content.match?(/\(\s*{\s*[^}]+}\s*\)/)
        props = content.scan(/props\.(\w+)/).flatten.uniq
        metrics[component_name][:prop_count] = props.size
      end
      
      # Count state usage (React)
      states = content.scan(/(?:useState|this\.state\.)(\w+)/).flatten.uniq
      metrics[component_name][:state_count] = states.size
      
      # Count effects (React)
      effects = content.scan(/useEffect/).size
      metrics[component_name][:effect_count] = effects
      
      # Check for component complexity
      if metrics[component_name][:method_count] > 7
        issues << {
          file: path,
          component: component_name,
          issue: "Component has #{metrics[component_name][:method_count]} methods. Consider breaking into smaller components."
        }
      end
      
      if metrics[component_name][:prop_count] > 8
        issues << {
          file: path,
          component: component_name,
          issue: "Component has #{metrics[component_name][:prop_count]} props. Consider breaking down or using composition."
        }
      end
      
      # Identify good practices
      if metrics[component_name][:method_count] <= 7 && 
         metrics[component_name][:prop_count] <= 8 &&
         metrics[component_name][:effect_count] <= 2
        good_examples << {
          file: path,
          component: component_name,
          note: "Well-structured component with focused responsibilities"
        }
      end
    end

    def generate_separation_feedback(issues, good_examples, metrics)
      feedback = []
      
      # Overall architecture assessment
      feedback << if metrics[:services].any?
        "The codebase shows good separation of concerns with dedicated service objects."
      else
        "Consider introducing service objects to better separate business logic."
      end
      
      # Controller assessment
      if metrics[:controllers].any?
        avg_actions = metrics[:controllers].values.map { |m| m[:action_count] }.sum.to_f / metrics[:controllers].size
        feedback << if avg_actions <= 7
          "Controllers are well-structured with focused responsibilities."
        else
          "Controllers average #{avg_actions.round(1)} actions, suggesting they might benefit from being broken down."
        end
      end
      
      # Model assessment
      if metrics[:models].any?
        fat_models = metrics[:models].select { |_, m| m[:instance_method_count] > 15 }.size
        feedback << if fat_models.zero?
          "Models maintain single responsibility and avoid excessive complexity."
        else
          "Found #{fat_models} complex models that might benefit from being broken down into smaller objects."
        end
      end
      
      # Highlight good examples
      if good_examples.any?
        feedback << "\nGood examples of separation of concerns:"
        good_examples.take(2).each do |example|
          feedback << "- #{example[:file]}: #{example[:note]}"
        end
      end
      
      # Highlight key issues
      if issues.any?
        feedback << "\nAreas for improvement:"
        issues.select { |i| i[:general] }.each do |issue|
          feedback << "- #{issue[:general]}"
        end
      end
      
      feedback.join("\n")
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
      issues = []
      good_examples = []
      total_lines = 0
      total_comment_lines = 0
      meaningful_comments = 0
      todo_fixme_count = 0

      files_to_analyze = ruby_files.merge(js_files)
      
      files_to_analyze.each do |path, content|
        lines = content.split("\n")
        file_lines = 0
        file_comment_lines = 0
        
        lines.each do |line|
          line = line.strip
          next if line.empty?
          
          file_lines += 1
          
          # Detect comments based on file type
          is_comment = case File.extname(path)
            when '.rb'
              line.start_with?('#')
            when '.js', '.ts'
              line.start_with?('//') || line.start_with?('/*') || line.end_with?('*/')
            else
              false
          end
          
          if is_comment
            file_comment_lines += 1
            
            # Check for TODOs and FIXMEs
            if line =~ /\b(TODO|FIXME)\b/i
              todo_fixme_count += 1
              issues << {
                file: path,
                line: file_lines,
                issue: "Found #{$1} comment - consider addressing technical debt"
              }
            end
            
            # Analyze comment quality
            comment_text = line.sub(/^[#\/\*]+\s*/, '') # Remove comment markers
            
            # Check if comment is meaningful (not just repeating code)
            if comment_text.length > 10 && !comment_text.include?('=') && 
               !comment_text.match?(/\b(end|private|public|protected)\b/)
              meaningful_comments += 1
              
              # Store good examples
              if comment_text.length > 20 && comment_text.match?(/\b(why|because|handles|prevents|ensures)\b/i)
                good_examples << {
                  file: path,
                  line: file_lines,
                  comment: comment_text
                }
              end
            end
          end
        end
        
        total_lines += file_lines
        total_comment_lines += file_comment_lines
        
        # Check for class/method documentation
        if path.end_with?('.rb')
          check_ruby_documentation(path, content, issues, good_examples)
        elsif path.end_with?('.js', '.ts')
          check_js_documentation(path, content, issues, good_examples)
        end
      end
      
      # Calculate scores
      comment_ratio = total_lines > 0 ? (total_comment_lines.to_f / total_lines) : 0
      meaningful_ratio = total_comment_lines > 0 ? (meaningful_comments.to_f / total_comment_lines) : 0
      
      # Base score calculation
      score = 10.0 # Start with max score
      
      # Deduct for low comment ratio (aim for 10-20% comments)
      if comment_ratio < 0.05
        score -= 3
        issues << { general: "Very low comment ratio (#{(comment_ratio * 100).round(1)}%). Consider adding more documentation." }
      elsif comment_ratio < 0.1
        score -= 1.5
        issues << { general: "Low comment ratio (#{(comment_ratio * 100).round(1)}%). Consider adding more documentation." }
      elsif comment_ratio > 0.3
        score -= 1
        issues << { general: "High comment ratio (#{(comment_ratio * 100).round(1)}%). Consider removing redundant comments." }
      end
      
      # Deduct for low meaningful comment ratio
      if meaningful_ratio < 0.5
        score -= 2
        issues << { general: "Many comments appear to be non-descriptive or redundant. Focus on explaining 'why' not 'what'." }
      end
      
      # Deduct for TODOs/FIXMEs
      if todo_fixme_count > 5
        score -= 1.5
        issues << { general: "High number of TODO/FIXME comments (#{todo_fixme_count}). Consider addressing technical debt." }
      end
      
      # Generate feedback
      feedback = generate_comments_feedback(issues, good_examples, comment_ratio, meaningful_ratio)
      
      {
        score: score.clamp(0, 10),
        feedback: feedback,
        details: {
          issues: issues,
          good_examples: good_examples,
          metrics: {
            comment_ratio: comment_ratio,
            meaningful_ratio: meaningful_ratio,
            todo_fixme_count: todo_fixme_count
          }
        }
      }
    end

    def check_ruby_documentation(path, content, issues, good_examples)
      # Check for class documentation
      classes = content.scan(/class\s+([A-Z]\w+)/)
      classes.each do |class_name|
        unless content.match?(/# .*\n\s*class\s+#{class_name[0]}/)
          issues << {
            file: path,
            class: class_name[0],
            issue: "Missing documentation for class #{class_name[0]}"
          }
        end
      end

      # Check for method documentation
      methods = content.scan(/def\s+(\w+)/)
      methods.each do |method_name|
        unless content.match?(/# .*\n\s*def\s+#{method_name[0]}/)
          issues << {
            file: path,
            method: method_name[0],
            issue: "Missing documentation for method #{method_name[0]}"
          }
        end
      end
    end

    def check_js_documentation(path, content, issues, good_examples)
      # Check for class/component documentation
      classes = content.scan(/class\s+([A-Z]\w+)|\bfunction\s+([A-Z]\w+)/)
      classes.each do |class_name|
        name = class_name[0] || class_name[1]
        unless content.match?(/\/\*\*[\s\S]*?\*\/\s*(?:export\s+)?(?:class|function)\s+#{name}/)
          issues << {
            file: path,
            class: name,
            issue: "Missing JSDoc documentation for class/component #{name}"
          }
        end
      end

      # Check for method documentation
      methods = content.scan(/(?:async\s+)?(?:function\s+(\w+)|(\w+)\s*:\s*function|\b(\w+)\s*=\s*(?:async\s+)?(?:\(|\s*=>))/)
      methods.each do |method_parts|
        method_name = method_parts.compact.first
        next if method_name.match?(/^(render|constructor|componentDid|componentWill|shouldComponent)/)
        
        unless content.match?(/\/\*\*[\s\S]*?\*\/\s*(?:async\s+)?(?:function\s+#{method_name}|\b#{method_name}\s*[:=])/)
          issues << {
            file: path,
            method: method_name,
            issue: "Missing JSDoc documentation for method #{method_name}"
          }
        end
      end
    end

    def generate_comments_feedback(issues, good_examples, comment_ratio, meaningful_ratio)
      feedback = []

      # Overall assessment
      feedback << case
        when comment_ratio < 0.05
          "The codebase is significantly under-documented with very few comments."
        when comment_ratio < 0.1
          "The codebase would benefit from additional documentation."
        when comment_ratio > 0.3
          "The codebase has a high number of comments. Consider focusing on code clarity instead of excessive comments."
        else
          "The codebase has a good balance of comments to code."
      end

      # Quality assessment
      feedback << case
        when meaningful_ratio < 0.3
          "Many comments are non-descriptive or simply repeat the code. Focus on explaining 'why' rather than 'what'."
        when meaningful_ratio < 0.5
          "Some comments could be more descriptive. The best comments explain the reasoning behind the code."
        else
          "Comments generally provide good context and explain the reasoning behind the code."
      end

      # Highlight good examples
      if good_examples.any?
        feedback << "\nGood documentation examples:"
        good_examples.take(2).each do |example|
          feedback << "- #{example[:file]}: #{example[:comment]}"
        end
      end

      # Highlight key issues
      if issues.any?
        feedback << "\nAreas for improvement:"
        issues.select { |i| i[:general] }.each do |issue|
          feedback << "- #{issue[:general]}"
        end
      end

      feedback.join("\n")
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

    def analyze_file_organization(ruby_files, js_files)
      issues = []
      good_examples = []
      
      # Initialize metrics
      metrics = {
        directory_structure: {
          models: [],
          controllers: [],
          views: [],
          services: [],
          helpers: [],
          concerns: [],
          components: [],
          assets: [],
          specs: [],
          other: []
        },
        file_sizes: {},
        namespace_usage: Set.new,
        framework_conventions: {
          followed: 0,
          violated: 0
        }
      }
      
      # Analyze Ruby files
      ruby_files.each do |path, content|
        analyze_ruby_file_organization(path, content, metrics, issues, good_examples)
      end
      
      # Analyze JavaScript/TypeScript files
      js_files.each do |path, content|
        analyze_js_file_organization(path, content, metrics, issues, good_examples)
      end
      
      # Calculate base score
      score = 10.0
      
      # Check directory structure
      if metrics[:directory_structure][:models].empty? && 
         metrics[:directory_structure][:controllers].any?
        score -= 1
        issues << { general: "Missing models directory structure in a Rails application." }
      end
      
      if metrics[:directory_structure][:services].empty? && 
         metrics[:directory_structure][:controllers].any? &&
         metrics[:directory_structure][:models].any?
        score -= 0.5
        issues << { general: "Consider adding a services directory for complex business logic." }
      end
      
      if metrics[:directory_structure][:concerns].empty? &&
         metrics[:directory_structure][:models].size > 5
        score -= 0.5
        issues << { general: "Consider using concerns for shared functionality across models." }
      end
      
      # Check file sizes
      large_files = metrics[:file_sizes].select { |_, size| size > 200 }
      if large_files.any?
        score -= [large_files.size * 0.5, 2].min
        issues << { general: "Found #{large_files.size} files with more than 200 lines. Consider breaking them down." }
      end
      
      # Check framework conventions
      if metrics[:framework_conventions][:violated] > 0
        score -= [metrics[:framework_conventions][:violated] * 0.5, 2].min
        issues << { general: "Found #{metrics[:framework_conventions][:violated]} violations of framework conventions." }
      end
      
      # Generate feedback
      feedback = generate_organization_feedback(issues, good_examples, metrics)
      
      {
        score: score.clamp(0, 10),
        feedback: feedback,
        details: {
          issues: issues,
          good_examples: good_examples,
          metrics: {
            directory_counts: metrics[:directory_structure].transform_values(&:size),
            large_files: large_files.size,
            convention_violations: metrics[:framework_conventions][:violated]
          }
        }
      }
    end

    def analyze_ruby_file_organization(path, content, metrics, issues, good_examples)
      # Categorize file by directory
      case path
      when /app\/models\//
        metrics[:directory_structure][:models] << path
        check_model_organization(path, content, metrics, issues, good_examples)
      when /app\/controllers\//
        metrics[:directory_structure][:controllers] << path
        check_controller_organization(path, content, metrics, issues, good_examples)
      when /app\/views\//
        metrics[:directory_structure][:views] << path
        check_view_organization(path, content, metrics, issues, good_examples)
      when /app\/services\//
        metrics[:directory_structure][:services] << path
        check_service_organization(path, content, metrics, issues, good_examples)
      when /app\/helpers\//
        metrics[:directory_structure][:helpers] << path
        check_helper_organization(path, content, metrics, issues, good_examples)
      when /app\/concerns\//
        metrics[:directory_structure][:concerns] << path
        check_concern_organization(path, content, metrics, issues, good_examples)
      else
        metrics[:directory_structure][:other] << path
      end
      
      # Check file size
      lines = content.split("\n").size
      metrics[:file_sizes][path] = lines
      
      if lines > 200
        issues << {
          file: path,
          issue: "File has #{lines} lines. Consider breaking it into smaller files."
        }
      end
      
      # Check namespacing
      namespace_matches = content.scan(/module\s+([A-Z]\w+)/)
      namespace_matches.each do |match|
        metrics[:namespace_usage].add(match[0])
      end
      
      # Check framework conventions
      check_framework_conventions(path, content, metrics, issues)
    end

    def analyze_js_file_organization(path, content, metrics, issues, good_examples)
      # Categorize file by directory
      if path.match?(/components?\//)
        metrics[:directory_structure][:components] << path
        check_component_organization(path, content, metrics, issues, good_examples)
      elsif path.match?(/assets?\//)
        metrics[:directory_structure][:assets] << path
      end
      
      # Check file size
      lines = content.split("\n").size
      metrics[:file_sizes][path] = lines
      
      if lines > 200
        issues << {
          file: path,
          issue: "File has #{lines} lines. Consider breaking it into smaller components."
        }
      end
      
      # Check component organization
      if path.end_with?('.jsx', '.tsx')
        check_react_conventions(path, content, metrics, issues)
      end
    end

    def check_model_organization(path, content, metrics, issues, good_examples)
      # Check model naming convention
      unless File.basename(path, '.rb').singularize == File.basename(path, '.rb')
        metrics[:framework_conventions][:violated] += 1
        issues << {
          file: path,
          issue: "Model filename should be singular (#{File.basename(path, '.rb')})."
        }
      end
      
      # Check if model matches table name convention
      class_name = File.basename(path, '.rb').camelize
      unless content.include?("class #{class_name} < ApplicationRecord") ||
             content.include?("class #{class_name} < ActiveRecord::Base")
        metrics[:framework_conventions][:violated] += 1
        issues << {
          file: path,
          issue: "Model class name should match filename and inherit from ApplicationRecord."
        }
      end
      
      # Good organization example
      if content.match?(/\A(?:class|module).*\n\s*(?:include\s+.*\n\s*)*(?:belongs_to|has_many|has_one).*\n\s*validates?/m)
        good_examples << {
          file: path,
          note: "Well-organized model with proper ordering of associations and validations"
        }
      end
    end

    def check_controller_organization(path, content, metrics, issues, good_examples)
      # Check controller naming convention
      unless File.basename(path, '.rb').end_with?('_controller')
        metrics[:framework_conventions][:violated] += 1
        issues << {
          file: path,
          issue: "Controller filename should end with '_controller.rb'."
        }
      end
      
      # Check if controller is properly namespaced
      if path.include?('/') && !content.include?('module')
        metrics[:framework_conventions][:violated] += 1
        issues << {
          file: path,
          issue: "Controller in subdirectory should be namespaced."
        }
      end
      
      # Good organization example
      if content.match?(/\A(?:class|module).*\n\s*(?:before_action.*\n\s*)*def\s+index/m)
        good_examples << {
          file: path,
          note: "Well-organized controller with proper action ordering"
        }
      end
    end

    def check_view_organization(path, content, metrics, issues, good_examples)
      # Check view naming convention
      unless path.match?(/app\/views\/\w+\/[\w.]+\.(?:erb|haml|slim)/)
        metrics[:framework_conventions][:violated] += 1
        issues << {
          file: path,
          issue: "View files should follow controller/action naming pattern."
        }
      end
      
      # Check partial naming
      if File.basename(path).start_with?('_')
        unless File.basename(path).match?(/^_[a-z][a-z0-9_]*\./)
          metrics[:framework_conventions][:violated] += 1
          issues << {
            file: path,
            issue: "Partial names should be snake_case and start with underscore."
          }
        end
      end
    end

    def check_service_organization(path, content, metrics, issues, good_examples)
      # Check service naming convention
      unless File.basename(path, '.rb').end_with?('_service')
        metrics[:framework_conventions][:violated] += 1
        issues << {
          file: path,
          issue: "Service filename should end with '_service.rb'."
        }
      end
      
      # Check service class structure
      if content.match?(/\A(?:class|module).*\n\s*(?:attr_reader|attr_accessor).*\n\s*def\s+initialize/m)
        good_examples << {
          file: path,
          note: "Well-organized service with proper initialization pattern"
        }
      end
    end

    def check_helper_organization(path, content, metrics, issues, good_examples)
      # Check helper naming convention
      unless File.basename(path, '.rb').end_with?('_helper')
        metrics[:framework_conventions][:violated] += 1
        issues << {
          file: path,
          issue: "Helper filename should end with '_helper.rb'."
        }
      end
      
      # Check if helper methods are properly modularized
      if content.scan(/def\s+\w+/).size > 10
        issues << {
          file: path,
          issue: "Helper has too many methods. Consider breaking it down or moving methods to more specific helpers."
        }
      end
    end

    def check_concern_organization(path, content, metrics, issues, good_examples)
      # Check concern naming convention
      unless File.basename(path, '.rb').end_with?('able')
        metrics[:framework_conventions][:violated] += 1
        issues << {
          file: path,
          issue: "Concern filename should end with 'able.rb' by convention."
        }
      end
      
      # Check concern module structure
      if content.match?(/\A(?:module\s+\w+\s*\n\s*extend\s+ActiveSupport::Concern\s*\n\s*included\s+do)/m)
        good_examples << {
          file: path,
          note: "Well-organized concern with proper ActiveSupport::Concern structure"
        }
      end
    end

    def check_component_organization(path, content, metrics, issues, good_examples)
      # Check component naming convention
      unless File.basename(path).match?(/^[A-Z]/)
        metrics[:framework_conventions][:violated] += 1
        issues << {
          file: path,
          issue: "React component filename should start with a capital letter."
        }
      end
      
      # Check component structure
      if content.match?(/import.*\n\s*(?:interface|type).*Props.*\n\s*(?:export\s+)?(?:default\s+)?(?:function|class)/m)
        good_examples << {
          file: path,
          note: "Well-organized component with proper TypeScript interface definitions"
        }
      end
    end

    def check_framework_conventions(path, content, metrics, issues)
      # Check basic Rails conventions
      if path.match?(/app\/models\/.*\.rb$/)
        metrics[:framework_conventions][:followed] += 1 if content.match?(/class\s+\w+\s*<\s*ApplicationRecord/)
      elsif path.match?(/app\/controllers\/.*\.rb$/)
        metrics[:framework_conventions][:followed] += 1 if content.match?(/class\s+\w+\s*<\s*ApplicationController/)
      end
      
      # Check for proper module nesting
      if path.include?('/') && !path.start_with?('app/views/')
        directory_modules = path.split('/')[2..-2] # Skip app/models etc.
        if directory_modules && directory_modules.any?
          expected_modules = directory_modules.map(&:camelize)
          actual_modules = content.scan(/module\s+([A-Z]\w+)/).flatten
          
          unless (expected_modules - actual_modules).empty?
            metrics[:framework_conventions][:violated] += 1
            issues << {
              file: path,
              issue: "File should be namespaced under #{expected_modules.join('::')}."
            }
          end
        end
      end
    end

    def check_react_conventions(path, content, metrics, issues)
      # Check for proper React component structure
      unless content.match?(/(?:export\s+default\s+function|class\s+\w+\s+extends\s+(?:React\.)?Component)/)
        metrics[:framework_conventions][:violated] += 1
        issues << {
          file: path,
          issue: "React component should be exported as default and follow function/class component pattern."
        }
      end
      
      # Check for proper prop types usage (if using TypeScript)
      if path.end_with?('.tsx') && !content.match?(/(?:interface|type)\s+\w+Props/)
        metrics[:framework_conventions][:violated] += 1
        issues << {
          file: path,
          issue: "TypeScript component should define Props interface/type."
        }
      end
    end

    def generate_organization_feedback(issues, good_examples, metrics)
      feedback = []
      
      # Overall structure assessment
      feedback << if metrics[:directory_structure].values.flatten.size > 20
        "The codebase follows a clear organizational structure with proper separation of concerns."
      else
        "The codebase is relatively small but should maintain clear organizational patterns as it grows."
      end
      
      # Framework conventions assessment
      convention_ratio = if metrics[:framework_conventions][:followed] + metrics[:framework_conventions][:violated] > 0
        metrics[:framework_conventions][:followed].to_f / 
        (metrics[:framework_conventions][:followed] + metrics[:framework_conventions][:violated])
      else
        1.0
      end
      
      feedback << case convention_ratio
        when 0.9..1.0
          "Excellent adherence to framework conventions."
        when 0.7..0.9
          "Good adherence to framework conventions with some minor inconsistencies."
        else
          "Consider improving adherence to framework conventions."
      end
      
      # File size assessment
      large_file_count = metrics[:file_sizes].count { |_, size| size > 200 }
      feedback << if large_file_count.zero?
        "Files are well-sized and focused."
      else
        "Found #{large_file_count} files that could benefit from being broken down into smaller units."
      end
      
      # Highlight good examples
      if good_examples.any?
        feedback << "\nGood organization examples:"
        good_examples.take(2).each do |example|
          feedback << "- #{example[:file]}: #{example[:note]}"
        end
      end
      
      # Highlight key issues
      if issues.any?
        feedback << "\nAreas for improvement:"
        issues.select { |i| i[:general] }.each do |issue|
          feedback << "- #{issue[:general]}"
        end
      end
      
      feedback.join("\n")
    end

    def analyze_dependencies
      issues = []
      good_examples = []
      
      # Initialize metrics
      metrics = {
        ruby_dependencies: {
          gems: {},
          versions: {},
          security_notices: [],
          unnecessary: []
        },
        js_dependencies: {
          packages: {},
          versions: {},
          dev_dependencies: {},
          security_notices: [],
          unnecessary: []
        },
        dependency_graphs: {
          circular: [],
          high_coupling: []
        }
      }
      
      # Analyze Ruby dependencies
      analyze_gemfile_dependencies(metrics, issues, good_examples)
      
      # Analyze JavaScript dependencies
      analyze_package_dependencies(metrics, issues, good_examples)
      
      # Calculate base score
      score = 10.0
      
      # Check for security vulnerabilities
      total_security_issues = metrics[:ruby_dependencies][:security_notices].size +
                            metrics[:js_dependencies][:security_notices].size
      if total_security_issues > 0
        score -= [total_security_issues * 1.0, 3.0].min
        issues << { general: "Found #{total_security_issues} potential security vulnerabilities in dependencies." }
      end
      
      # Check for unnecessary dependencies
      total_unnecessary = metrics[:ruby_dependencies][:unnecessary].size +
                         metrics[:js_dependencies][:unnecessary].size
      if total_unnecessary > 0
        score -= [total_unnecessary * 0.5, 2.0].min
        issues << { general: "Found #{total_unnecessary} potentially unnecessary dependencies." }
      end
      
      # Check for circular dependencies
      if metrics[:dependency_graphs][:circular].any?
        score -= [metrics[:dependency_graphs][:circular].size * 1.0, 2.0].min
        issues << { general: "Found #{metrics[:dependency_graphs][:circular].size} circular dependencies." }
      end
      
      # Check for high coupling
      if metrics[:dependency_graphs][:high_coupling].any?
        score -= [metrics[:dependency_graphs][:high_coupling].size * 0.5, 2.0].min
        issues << { general: "Found #{metrics[:dependency_graphs][:high_coupling].size} instances of high dependency coupling." }
      end
      
      # Generate feedback
      feedback = generate_dependency_feedback(issues, good_examples, metrics)
      
      {
        score: score.clamp(0, 10),
        feedback: feedback,
        details: {
          issues: issues,
          good_examples: good_examples,
          metrics: {
            security_issues: total_security_issues,
            unnecessary_deps: total_unnecessary,
            circular_deps: metrics[:dependency_graphs][:circular].size,
            high_coupling: metrics[:dependency_graphs][:high_coupling].size
          }
        }
      }
    end

    private

    def analyze_gemfile_dependencies(metrics, issues, good_examples)
      return unless File.exist?('Gemfile')
      
      gemfile_content = File.read('Gemfile')
      lockfile_content = File.exist?('Gemfile.lock') ? File.read('Gemfile.lock') : nil
      
      # Parse Gemfile
      gemfile_content.each_line do |line|
        if line =~ /^\s*gem\s+['"]([^'"]+)['"](?:,\s*['"]([^'"]+)['"])?/
          gem_name = $1
          version = $2
          
          metrics[:ruby_dependencies][:gems][gem_name] = {
            version: version,
            groups: [],
            source: 'rubygems'
          }
          
          # Check version specification
          if version.nil?
            issues << {
              dependency: gem_name,
              issue: "No version specified for gem '#{gem_name}'. Consider pinning to a specific version."
            }
          end
        end
      end
      
      # Parse Gemfile.lock if available
      if lockfile_content
        current_gem = nil
        lockfile_content.each_line do |line|
          if line =~ /^\s{4}([^\s(]+)\s+\((.*)\)/
            current_gem = $1
            metrics[:ruby_dependencies][:versions][current_gem] = $2
          end
        end
      end
      
      # Analyze common unnecessary gems
      unnecessary_gems = []
      
      metrics[:ruby_dependencies][:gems].each do |gem_name, details|
        case gem_name
        when 'coffee-rails'
          unnecessary_gems << {
            name: gem_name,
            reason: "CoffeeScript is largely obsolete. Consider using modern JavaScript."
          }
        when 'jquery-rails'
          unnecessary_gems << {
            name: gem_name,
            reason: "Consider if jQuery is necessary in modern applications."
          }
        when 'therubyracer'
          unnecessary_gems << {
            name: gem_name,
            reason: "Not needed if using Node.js as JavaScript runtime."
          }
        end
      end
      
      metrics[:ruby_dependencies][:unnecessary].concat(unnecessary_gems)
      
      # Check for security vulnerabilities
      check_ruby_security_vulnerabilities(metrics, issues)
      
      # Identify good practices
      identify_good_ruby_practices(metrics, good_examples)
    end

    def analyze_package_dependencies(metrics, issues, good_examples)
      return unless File.exist?('package.json')
      
      package_json = JSON.parse(File.read('package.json'))
      
      # Analyze dependencies
      if package_json['dependencies']
        package_json['dependencies'].each do |pkg_name, version|
          metrics[:js_dependencies][:packages][pkg_name] = {
            version: version,
            type: 'production'
          }
          
          # Check version specification
          if version.start_with?('^') || version.start_with?('~')
            issues << {
              dependency: pkg_name,
              issue: "Consider pinning #{pkg_name} to a specific version instead of using #{version}"
            }
          end
        end
      end
      
      # Analyze devDependencies
      if package_json['devDependencies']
        package_json['devDependencies'].each do |pkg_name, version|
          metrics[:js_dependencies][:dev_dependencies][pkg_name] = {
            version: version,
            type: 'development'
          }
        end
      end
      
      # Check for unnecessary dependencies
      check_unnecessary_js_dependencies(metrics, issues)
      
      # Check for security vulnerabilities
      check_js_security_vulnerabilities(metrics, issues)
      
      # Check package-lock.json or yarn.lock
      check_lock_files(metrics, issues)
      
      # Identify good practices
      identify_good_js_practices(metrics, good_examples)
    end

    def check_ruby_security_vulnerabilities(metrics, issues)
      # This would typically integrate with a security advisory database
      # For now, we'll check for commonly known vulnerable versions
      metrics[:ruby_dependencies][:gems].each do |gem_name, details|
        case gem_name
        when 'rails'
          if details[:version] && details[:version] < '5.2.4.3'
            metrics[:ruby_dependencies][:security_notices] << {
              gem: gem_name,
              version: details[:version],
              advisory: "Rails versions below 5.2.4.3 have known security vulnerabilities."
            }
          end
        when 'nokogiri'
          if details[:version] && details[:version] < '1.10.8'
            metrics[:ruby_dependencies][:security_notices] << {
              gem: gem_name,
              version: details[:version],
              advisory: "Nokogiri versions below 1.10.8 have known security vulnerabilities."
            }
          end
        end
      end
    end

    def check_js_security_vulnerabilities(metrics, issues)
      # This would typically integrate with npm audit or similar
      # For now, we'll check for commonly known vulnerable versions
      metrics[:js_dependencies][:packages].each do |pkg_name, details|
        case pkg_name
        when 'lodash'
          if details[:version] && details[:version] < '4.17.19'
            metrics[:js_dependencies][:security_notices] << {
              package: pkg_name,
              version: details[:version],
              advisory: "Lodash versions below 4.17.19 have known security vulnerabilities."
            }
          end
        when 'jquery'
          if details[:version] && details[:version] < '3.5.0'
            metrics[:js_dependencies][:security_notices] << {
              package: pkg_name,
              version: details[:version],
              advisory: "jQuery versions below 3.5.0 have known security vulnerabilities."
            }
          end
        end
      end
    end

    def check_unnecessary_js_dependencies(metrics, issues)
      # Check for potentially unnecessary dependencies
      metrics[:js_dependencies][:packages].each do |pkg_name, details|
        case pkg_name
        when 'moment'
          metrics[:js_dependencies][:unnecessary] << {
            name: pkg_name,
            reason: "Consider using native Date methods or lighter alternatives like date-fns"
          }
        when 'lodash', 'underscore'
          metrics[:js_dependencies][:unnecessary] << {
            name: pkg_name,
            reason: "Many lodash/underscore functions are now available in native JavaScript"
          }
        when 'jquery'
          metrics[:js_dependencies][:unnecessary] << {
            name: pkg_name,
            reason: "Modern DOM APIs can replace most jQuery functionality"
          }
        end
      end
    end

    def check_lock_files(metrics, issues)
      # Check for presence of lock files
      unless File.exist?('package-lock.json') || File.exist?('yarn.lock')
        issues << {
          general: "No package lock file found. Add package-lock.json or yarn.lock for consistent installations."
        }
      end
      
      # If using npm, warn about yarn.lock
      if File.exist?('package-lock.json') && File.exist?('yarn.lock')
        issues << {
          general: "Both package-lock.json and yarn.lock found. Choose one package manager."
        }
      end
    end

    def identify_good_ruby_practices(metrics, good_examples)
      # Check for good version management
      metrics[:ruby_dependencies][:gems].each do |gem_name, details|
        if details[:version] && !details[:version].include?('>=')
          good_examples << {
            dependency: gem_name,
            note: "Well-specified version constraint for #{gem_name}"
          }
        end
      end
      
      # Check for good gem organization
      if metrics[:ruby_dependencies][:gems].values.any? { |g| g[:groups].include?('development') } &&
         metrics[:ruby_dependencies][:gems].values.any? { |g| g[:groups].include?('test') }
        good_examples << {
          general: "Good separation of development and test dependencies"
        }
      end
    end

    def identify_good_js_practices(metrics, good_examples)
      # Check for good version pinning
      metrics[:js_dependencies][:packages].each do |pkg_name, details|
        if details[:version] && !details[:version].start_with?('^', '~')
          good_examples << {
            dependency: pkg_name,
            note: "Well-pinned version for #{pkg_name}"
          }
        end
      end
      
      # Check for good dependency organization
      if metrics[:js_dependencies][:dev_dependencies].any? &&
         metrics[:js_dependencies][:packages].any?
        good_examples << {
          general: "Good separation of production and development dependencies"
        }
      end
    end

    def generate_dependency_feedback(issues, good_examples, metrics)
      feedback = []
      
      # Overall dependency assessment
      total_deps = metrics[:ruby_dependencies][:gems].size +
                  metrics[:js_dependencies][:packages].size
      
      feedback << if total_deps > 0
        "Project uses #{total_deps} dependencies across Ruby and JavaScript."
      else
        "No dependencies found. This might indicate a minimal project or missing dependency files."
      end
      
      # Security assessment
      if metrics[:ruby_dependencies][:security_notices].empty? &&
         metrics[:js_dependencies][:security_notices].empty?
        feedback << "No known security vulnerabilities found in dependencies."
      else
        feedback << "Found #{metrics[:ruby_dependencies][:security_notices].size + metrics[:js_dependencies][:security_notices].size} potential security vulnerabilities that should be addressed."
      end
      
      # Dependency management assessment
      if metrics[:ruby_dependencies][:unnecessary].empty? &&
         metrics[:js_dependencies][:unnecessary].empty?
        feedback << "Dependencies appear to be well-managed with no obvious unnecessary inclusions."
      else
        feedback << "Found #{metrics[:ruby_dependencies][:unnecessary].size + metrics[:js_dependencies][:unnecessary].size} potentially unnecessary dependencies that could be removed or replaced."
      end
      
      # Highlight good examples
      if good_examples.any?
        feedback << "\nGood dependency practices:"
        good_examples.take(2).each do |example|
          if example[:dependency]
            feedback << "- #{example[:dependency]}: #{example[:note]}"
          else
            feedback << "- #{example[:general]}"
          end
        end
      end
      
      # Highlight key issues
      if issues.any?
        feedback << "\nAreas for improvement:"
        issues.select { |i| i[:general] }.each do |issue|
          feedback << "- #{issue[:general]}"
        end
      end
      
      feedback.join("\n")
    end

    def analyze_framework_usage(ruby_files, js_files)
      issues = []
      good_examples = []
      
      # Initialize metrics
      metrics = {
        rails: {
          patterns: {
            followed: [],
            violated: []
          },
          features: {
            used: Set.new,
            unused: Set.new,
            misused: []
          },
          performance: {
            issues: [],
            optimizations: []
          }
        },
        react: {
          patterns: {
            followed: [],
            violated: []
          },
          features: {
            used: Set.new,
            unused: Set.new,
            misused: []
          },
          performance: {
            issues: [],
            optimizations: []
          }
        }
      }
      
      # Analyze Ruby/Rails files
      ruby_files.each do |path, content|
        if path.start_with?('app/')
          analyze_rails_patterns(path, content, metrics, issues, good_examples)
        end
      end
      
      # Analyze JavaScript/React files
      js_files.each do |path, content|
        if path.end_with?('.jsx', '.tsx', '.js', '.ts')
          analyze_react_patterns(path, content, metrics, issues, good_examples)
        end
      end
      
      # Calculate base score
      score = 10.0
      
      # Evaluate Rails patterns
      if metrics[:rails][:patterns][:violated].any?
        score -= [metrics[:rails][:patterns][:violated].size * 0.5, 2.0].min
        issues << { general: "Found #{metrics[:rails][:patterns][:violated].size} violations of Rails conventions." }
      end
      
      # Evaluate React patterns
      if metrics[:react][:patterns][:violated].any?
        score -= [metrics[:react][:patterns][:violated].size * 0.5, 2.0].min
        issues << { general: "Found #{metrics[:react][:patterns][:violated].size} violations of React best practices." }
      end
      
      # Check feature usage
      rails_unused = metrics[:rails][:features][:unused].size
      react_unused = metrics[:react][:features][:unused].size
      if rails_unused + react_unused > 0
        score -= [(rails_unused + react_unused) * 0.3, 1.5].min
        issues << { general: "Found #{rails_unused + react_unused} framework features that could be better utilized." }
      end
      
      # Check performance issues
      total_perf_issues = metrics[:rails][:performance][:issues].size +
                         metrics[:react][:performance][:issues].size
      if total_perf_issues > 0
        score -= [total_perf_issues * 0.5, 2.0].min
        issues << { general: "Found #{total_perf_issues} potential performance issues in framework usage." }
      end
      
      # Generate feedback
      feedback = generate_framework_feedback(issues, good_examples, metrics)
      
      {
        score: score.clamp(0, 10),
        feedback: feedback,
        details: {
          issues: issues,
          good_examples: good_examples,
          metrics: {
            rails_violations: metrics[:rails][:patterns][:violated].size,
            react_violations: metrics[:react][:patterns][:violated].size,
            unused_features: rails_unused + react_unused,
            performance_issues: total_perf_issues
          }
        }
      }
    end

    def analyze_rails_patterns(path, content, metrics, issues, good_examples)
      # Check controller patterns
      if path.include?('app/controllers/')
        analyze_rails_controller(path, content, metrics, issues, good_examples)
      end
      
      # Check model patterns
      if path.include?('app/models/')
        analyze_rails_model(path, content, metrics, issues, good_examples)
      end
      
      # Check view patterns
      if path.include?('app/views/')
        analyze_rails_view(path, content, metrics, issues, good_examples)
      end
      
      # Check mailer patterns
      if path.include?('app/mailers/')
        analyze_rails_mailer(path, content, metrics, issues, good_examples)
      end
      
      # Check job patterns
      if path.include?('app/jobs/')
        analyze_rails_job(path, content, metrics, issues, good_examples)
      end
    end

    def analyze_rails_controller(path, content, metrics, issues, good_examples)
      # Check for fat controller anti-pattern
      action_lines = content.scan(/def\s+\w+/).size
      business_logic_lines = content.scan(/\b(where|find_by|order|includes|joins|select|group|having)\b/).size
      
      if business_logic_lines > 10
        metrics[:rails][:patterns][:violated] << {
          file: path,
          pattern: "fat_controller",
          description: "Controller contains significant business logic"
        }
      end
      
      # Check for proper use of strong parameters
      unless content.include?('params.require') || content.include?('params.permit')
        metrics[:rails][:patterns][:violated] << {
          file: path,
          pattern: "missing_strong_params",
          description: "Controller should use strong parameters"
        }
      end
      
      # Check for proper use of callbacks
      if content.match?(/before_action\s+:authenticate/)
        metrics[:rails][:patterns][:followed] << {
          file: path,
          pattern: "authentication_callback",
          description: "Proper use of authentication callbacks"
        }
      end
      
      # Check for proper REST actions
      if content.match?(/\b(index|show|new|create|edit|update|destroy)\b/)
        metrics[:rails][:features][:used].add('rest_actions')
      end
      
      # Check for N+1 query potential
      if content.match?(/\.each.*\b(where|find_by)\b/m)
        metrics[:rails][:performance][:issues] << {
          file: path,
          issue: "Potential N+1 query detected"
        }
      end
    end

    def analyze_rails_model(path, content, metrics, issues, good_examples)
      # Check for proper use of validations
      if content.match?(/\b(validates|validate|validates_presence_of|validates_uniqueness_of)\b/)
        metrics[:rails][:patterns][:followed] << {
          file: path,
          pattern: "model_validations",
          description: "Model uses proper validations"
        }
      end
      
      # Check for proper use of associations
      if content.match?(/\b(belongs_to|has_many|has_one|has_and_belongs_to_many)\b/)
        metrics[:rails][:patterns][:followed] << {
          file: path,
          pattern: "model_associations",
          description: "Model uses proper associations"
        }
      end
      
      # Check for callback abuse
      callback_count = content.scan(/\b(before_save|after_save|before_create|after_create)\b/).size
      if callback_count > 3
        metrics[:rails][:patterns][:violated] << {
          file: path,
          pattern: "callback_abuse",
          description: "Model has excessive callbacks"
        }
      end
      
      # Check for proper scopes
      if content.match?(/\bscope\s+:/)
        metrics[:rails][:features][:used].add('model_scopes')
      else
        metrics[:rails][:features][:unused].add('model_scopes')
      end
      
      # Check for missing indexes
      if content.match?(/belongs_to\s+:(\w+)/) && !content.match?(/index:\s+true/)
        metrics[:rails][:performance][:issues] << {
          file: path,
          issue: "Missing index on belongs_to association"
        }
      end
    end

    def analyze_rails_view(path, content, metrics, issues, good_examples)
      # Check for proper use of partials
      if path.start_with?('_')
        metrics[:rails][:features][:used].add('partials')
      end
      
      # Check for raw SQL in views
      if content.match?(/<%=\s*.*\.execute\s*\(?["']SELECT/i)
        metrics[:rails][:patterns][:violated] << {
          file: path,
          pattern: "sql_in_view",
          description: "Raw SQL in view template"
        }
      end
      
      # Check for proper helper usage
      if content.match?(/<%=\s*\w+_helper/)
        metrics[:rails][:features][:used].add('view_helpers')
      end
      
      # Check for excessive logic in views
      if content.scan(/<%/).size > 20
        metrics[:rails][:patterns][:violated] << {
          file: path,
          pattern: "excessive_view_logic",
          description: "View contains excessive embedded Ruby"
        }
      end
    end

    def analyze_rails_mailer(path, content, metrics, issues, good_examples)
      # Check for proper mailer setup
      if content.match?(/class\s+\w+\s*<\s*ApplicationMailer/)
        metrics[:rails][:patterns][:followed] << {
          file: path,
          pattern: "mailer_inheritance",
          description: "Proper mailer class inheritance"
        }
      end
      
      # Check for background processing
      unless content.match?(/deliver_later/)
        metrics[:rails][:features][:unused].add('background_mailers')
        metrics[:rails][:performance][:issues] << {
          file: path,
          issue: "Mailer not using background processing"
        }
      end
    end

    def analyze_rails_job(path, content, metrics, issues, good_examples)
      # Check for proper job setup
      if content.match?(/class\s+\w+\s*<\s*ApplicationJob/)
        metrics[:rails][:patterns][:followed] << {
          file: path,
          pattern: "job_inheritance",
          description: "Proper job class inheritance"
        }
      end
      
      # Check for retry configuration
      if content.match?(/retry_on|discard_on/)
        metrics[:rails][:features][:used].add('job_retries')
      else
        metrics[:rails][:features][:unused].add('job_retries')
      end
    end

    def analyze_react_patterns(path, content, metrics, issues, good_examples)
      # Check for proper component structure
      if content.match?(/(?:export\s+default\s+function|class\s+\w+\s+extends\s+(?:React\.)?Component)/)
        metrics[:react][:patterns][:followed] << {
          file: path,
          pattern: "component_structure",
          description: "Proper component declaration"
        }
      end
      
      # Check for prop types usage
      if path.end_with?('.tsx')
        if content.match?(/(?:interface|type)\s+\w+Props/)
          metrics[:react][:patterns][:followed] << {
            file: path,
            pattern: "typescript_props",
            description: "Proper TypeScript props definition"
          }
        else
          metrics[:react][:patterns][:violated] << {
            file: path,
            pattern: "missing_prop_types",
            description: "Missing TypeScript props interface"
          }
        end
      end
      
      # Check for hooks usage
      hooks_used = content.scan(/use[A-Z]\w+/).uniq
      hooks_used.each do |hook|
        metrics[:react][:features][:used].add(hook)
      end
      
      # Check for proper useEffect dependencies
      if content.match?(/useEffect\([^,]+,\s*\[\]/)
        metrics[:react][:patterns][:violated] << {
          file: path,
          pattern: "empty_effect_deps",
          description: "useEffect with empty dependency array"
        }
      end
      
      # Check for performance optimizations
      if content.match?(/React\.memo|useMemo|useCallback/)
        metrics[:react][:features][:used].add('performance_optimizations')
      else if content.match?(/(?:map|filter|reduce).*(?:map|filter|reduce)/)
        metrics[:react][:performance][:issues] << {
          file: path,
          issue: "Multiple array operations without memoization"
        }
      end
      
      # Check for proper event handling
      if content.match?(/on\w+\s*=\s*{[^}]*\.\s*bind\(this\)}/)
        metrics[:react][:patterns][:violated] << {
          file: path,
          pattern: "bind_in_render",
          description: "Method binding in render"
        }
      end
    end

    def generate_framework_feedback(issues, good_examples, metrics)
      feedback = []
      
      # Rails assessment
      if metrics[:rails][:patterns][:followed].any? || metrics[:rails][:patterns][:violated].any?
        total_rails_patterns = metrics[:rails][:patterns][:followed].size + metrics[:rails][:patterns][:violated].size
        followed_ratio = metrics[:rails][:patterns][:followed].size.to_f / total_rails_patterns
        
        feedback << case followed_ratio
          when 0.8..1.0
            "Excellent adherence to Rails conventions and best practices."
          when 0.6..0.8
            "Good adherence to Rails conventions with some areas for improvement."
          else
            "Consider improving adherence to Rails conventions and best practices."
        end
        
        # Feature usage
        if metrics[:rails][:features][:used].any?
          feedback << "Good utilization of Rails features including: #{metrics[:rails][:features][:used].to_a.join(', ')}."
        end
        
        if metrics[:rails][:features][:unused].any?
          feedback << "Consider utilizing these Rails features: #{metrics[:rails][:features][:unused].to_a.join(', ')}."
        end
      end
      
      # React assessment
      if metrics[:react][:patterns][:followed].any? || metrics[:react][:patterns][:violated].any?
        total_react_patterns = metrics[:react][:patterns][:followed].size + metrics[:react][:patterns][:violated].size
        followed_ratio = metrics[:react][:patterns][:followed].size.to_f / total_react_patterns
        
        feedback << case followed_ratio
          when 0.8..1.0
            "Excellent adherence to React best practices."
          when 0.6..0.8
            "Good adherence to React best practices with some areas for improvement."
          else
            "Consider improving adherence to React best practices."
        end
        
        # Feature usage
        if metrics[:react][:features][:used].any?
          feedback << "Good utilization of React features including: #{metrics[:react][:features][:used].to_a.join(', ')}."
        end
      end
      
      # Performance issues
      if metrics[:rails][:performance][:issues].any? || metrics[:react][:performance][:issues].any?
        feedback << "\nPerformance considerations:"
        metrics[:rails][:performance][:issues].each do |issue|
          feedback << "- Rails: #{issue[:issue]}"
        end
        metrics[:react][:performance][:issues].each do |issue|
          feedback << "- React: #{issue[:issue]}"
        end
      end
      
      # Highlight good examples
      if good_examples.any?
        feedback << "\nGood framework usage examples:"
        good_examples.take(2).each do |example|
          feedback << "- #{example[:file]}: #{example[:note]}"
        end
      end
      
      # Highlight key issues
      if issues.any?
        feedback << "\nAreas for improvement:"
        issues.select { |i| i[:general] }.each do |issue|
          feedback << "- #{issue[:general]}"
        end
      end
      
      feedback.join("\n")
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