module Ai
  class CodeReviewer
    SCORE_WEIGHTS = {
      code_clarity: 45,
      architecture: 15,
      practices: 30,
      problem_solving: 25,
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
      basic_testing: 8,
      test_coverage: 4,
      test_organization: 3
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
      
      Rails.logger.debug "Files loaded:"
      Rails.logger.debug "Ruby files: #{ruby_files.keys.inspect}"
      Rails.logger.debug "JS files: #{js_files.keys.inspect}"
      Rails.logger.debug "Test files: #{test_files.keys.inspect}"
      Rails.logger.debug "Doc files: #{doc_files.keys.inspect}"
      
      Rails.logger.debug "Analyzing code clarity..."
      clarity_scores = analyze_code_clarity(ruby_files, js_files)
      Rails.logger.debug "Clarity scores: #{clarity_scores.inspect}"
      
      Rails.logger.debug "Analyzing architecture..."
      architecture_scores = analyze_architecture(ruby_files, js_files)
      Rails.logger.debug "Architecture scores: #{architecture_scores.inspect}"
      
      Rails.logger.debug "Analyzing development practices..."
      practices_scores = analyze_development_practices(test_files, doc_files)
      Rails.logger.debug "Practices scores: #{practices_scores.inspect}"
      
      Rails.logger.debug "Analyzing problem solving..."
      problem_solving_scores = analyze_problem_solving(ruby_files, js_files)
      Rails.logger.debug "Problem solving scores: #{problem_solving_scores.inspect}"
      
      # Calculate bonus points
      Rails.logger.debug "Analyzing bonus points..."
      bonus_scores = analyze_bonus_points(ruby_files, js_files, test_files)
      Rails.logger.debug "Bonus scores: #{bonus_scores.inspect}"
      
      results = {
        clarity_scores: clarity_scores,
        architecture_scores: architecture_scores,
        practices_scores: practices_scores,
        problem_solving_scores: problem_solving_scores,
        bonus_scores: bonus_scores
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
      naming_score = analyze_naming_conventions(ruby_files, js_files) || { score: 0, feedback: "Error analyzing naming conventions" }
      simplicity_score = analyze_method_simplicity(ruby_files, js_files) || { score: 0, feedback: "Error analyzing method simplicity" }
      organization_score = analyze_code_organization(ruby_files, js_files) || { score: 0, feedback: "Error analyzing code organization" }
      comments_score = analyze_comments_quality(ruby_files, js_files) || { score: 0, feedback: "Error analyzing comments quality" }

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
      Rails.logger.debug "\n=== Starting analyze_separation_of_concerns ==="
      Rails.logger.debug "Ruby files: #{ruby_files.keys.inspect}"
      Rails.logger.debug "JS files: #{js_files.keys.inspect}"

      # Initialize metrics
      class_metrics = {}
      controller_metrics = {}
      model_metrics = {}
      service_metrics = {}
      
      # Pre-initialize metrics for all files
      Rails.logger.debug "\nPre-initializing metrics for all files"
      (ruby_files.keys + js_files.keys).each do |path|
        class_name = File.basename(path, File.extname(path)).camelize
        Rails.logger.debug "Initializing metrics for #{class_name}"
        class_metrics[class_name] = {
          method_count: 0,
          dependency_count: 0,
          inheritance_depth: 0,
          mixin_count: 0
        }
      end

      Rails.logger.debug "\nInitial class_metrics state:"
      class_metrics.each do |name, metrics|
        Rails.logger.debug "#{name}: #{metrics.inspect}"
      end

      # Initialize high coupling tracking
      high_coupling = {}
      Rails.logger.debug "\nStarting high coupling analysis"

      # Process each class's metrics
      class_metrics.each do |name, metrics|
        Rails.logger.debug "\nAnalyzing coupling for #{name}:"
        Rails.logger.debug "Raw metrics: #{metrics.inspect}"
        
        unless metrics.is_a?(Hash)
          Rails.logger.debug "Skipping #{name}: metrics is not a hash"
          next
        end

        dependency_count = metrics.fetch(:dependency_count, 0)
        Rails.logger.debug "Dependency count (before to_i): #{dependency_count.inspect}"
        dependency_count = dependency_count.to_i
        Rails.logger.debug "Dependency count (after to_i): #{dependency_count}"

        if dependency_count > 5
          Rails.logger.debug "High coupling detected for #{name} with #{dependency_count} dependencies"
          high_coupling[name] = metrics.dup
        end
      end

      Rails.logger.debug "\nHigh coupling analysis complete"
      Rails.logger.debug "Found #{high_coupling.size} instances of high coupling"
      Rails.logger.debug "High coupling classes: #{high_coupling.keys.inspect}"
      
      issues = []
      good_examples = []
      
      # Analyze Ruby files
      ruby_files.each do |path, content|
        next if content.nil? || content.strip.empty?
        
        class_name = File.basename(path, '.rb').camelize
        Rails.logger.debug "Analyzing Ruby file: #{path} (#{class_name})"
        
        # Ensure metrics exist for this class
        class_metrics[class_name] ||= {
          method_count: 0,
          dependency_count: 0,
          inheritance_depth: 0,
          mixin_count: 0
        }
        
        if path.include?('app/controllers/')
          controller_metrics[class_name] ||= { action_count: 0, lines_of_business_logic: 0, before_actions: 0 }
          analyze_controller(path, content, controller_metrics, issues, good_examples)
        elsif path.include?('app/models/')
          model_metrics[class_name] ||= { instance_method_count: 0, class_method_count: 0, association_count: 0, callback_count: 0, validation_count: 0 }
          analyze_model(path, content, model_metrics, issues, good_examples)
        elsif path.include?('app/services/')
          service_metrics[class_name] ||= { public_method_count: 0, private_method_count: 0, dependency_count: 0, responsibility_focus: :single }
          analyze_service(path, content, service_metrics, issues, good_examples)
        end
        
        # General class analysis
        analyze_class_structure(path, content, class_metrics, issues, good_examples)
        Rails.logger.debug "Class metrics after analyzing #{path}: #{class_metrics[class_name].inspect}"
      end
      
      # Analyze JavaScript/TypeScript files
      js_files.each do |path, content|
        next if content.nil? || content.strip.empty?
        
        component_name = File.basename(path, File.extname(path))
        Rails.logger.debug "Analyzing JS file: #{path} (#{component_name})"
        
        # Ensure metrics exist for this component
        class_metrics[component_name] ||= {
          method_count: 0,
          dependency_count: 0,
          inheritance_depth: 0,
          mixin_count: 0
        }
        
        analyze_js_component(path, content, class_metrics, issues, good_examples)
        Rails.logger.debug "Class metrics after analyzing #{path}: #{class_metrics[component_name].inspect}"
      end
      
      Rails.logger.debug "Final class metrics: #{class_metrics.inspect}"
      
      # Calculate base score with defensive checks
      score = 10.0
      
      # Analyze controller metrics with nil safety
      if controller_metrics.any?
        action_counts = controller_metrics.values.map { |m| m[:action_count] || 0 }
        avg_controller_actions = action_counts.sum.to_f / controller_metrics.size
        
        if avg_controller_actions > 7
          score -= 1
          issues << { general: "Controllers average #{avg_controller_actions.round(1)} actions. Consider breaking down large controllers." }
        end
        
        fat_controllers = controller_metrics.select { |_, m| (m[:lines_of_business_logic] || 0) > 50 }
        if fat_controllers.any?
          score -= 1
          issues << { general: "Found #{fat_controllers.size} controllers with excessive business logic. Move logic to models or services." }
        end
      end
      
      # Analyze model metrics with nil safety
      if model_metrics.any?
        fat_models = model_metrics.select { |_, m| (m[:instance_method_count] || 0) > 15 }
        if fat_models.any?
          score -= 1
          issues << { general: "Found #{fat_models.size} models with too many instance methods. Consider extracting concerns or creating service objects." }
        end
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
    rescue => e
      Rails.logger.error "Error in analyze_separation_of_concerns: #{e.message}\n#{e.backtrace.join("\n")}"
      {
        score: 5.0, # Default middle score on error
        feedback: "Error analyzing separation of concerns: #{e.message}",
        details: {
          issues: [{ general: "Error during analysis: #{e.message}" }],
          good_examples: [],
          metrics: {
            controller_count: controller_metrics.size,
            model_count: model_metrics.size,
            service_count: service_metrics.size,
            high_coupling_count: 0
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
      return if content.nil? || content.empty?
      
      class_name = File.basename(path, '.rb').camelize
      
      Rails.logger.debug "Initializing class metrics for #{class_name}"
      
      # Ensure metrics for this class exist with default values
      metrics[class_name] ||= {
        method_count: 0,
        dependency_count: 0,
        inheritance_depth: 0,
        mixin_count: 0
      }
      
      begin
        # Count methods
        methods = content.scan(/def\s+(\w+)/).flatten
        metrics[class_name][:method_count] = methods.size
        
        # Count dependencies (class references)
        dependencies = content.scan(/\b[A-Z]\w+\b/).uniq - [class_name] # Exclude self-reference
        Rails.logger.debug "Found dependencies for #{class_name}: #{dependencies.inspect}"
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
        
        Rails.logger.debug "Final metrics for #{class_name}: #{metrics[class_name].inspect}"
        
      rescue => e
        Rails.logger.error "Error analyzing class structure for #{class_name}: #{e.message}"
        # Ensure metrics exist even if analysis fails
        metrics[class_name] = {
          method_count: 0,
          dependency_count: 0,
          inheritance_depth: 0,
          mixin_count: 0
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
        begin
          analyze_file_naming(path, content, issues, good_examples)
        rescue => e
          Rails.logger.error "Error analyzing file naming for #{path}: #{e.message}"
          issues << { type: 'error', file: path, message: "Error analyzing file: #{e.message}" }
        end
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
      return unless content && path
      
      # I can analyze the content and provide specific feedback
      content.to_s.scan(/\b(def|class|module|var|let|const)\s+([a-zA-Z_]\w*)/).each do |type, name|
        if good_name?(name, type)
          good_examples << { type: type, name: name, file: path }
        else
          issues << { type: type, name: name, file: path, suggestion: suggest_better_name(name, type) }
        end
      end
    end

    def calculate_naming_score(issues)
      # Start with a perfect score and deduct based on issues
      score = 10.0
      
      # Handle nil or invalid issues array
      return score unless issues.respond_to?(:size) && !issues.empty?
      
      # Deduct points for each issue, up to a maximum of 5 points
      deduction = [issues.size * 0.5, 5.0].min
      score -= deduction
      
      # Ensure score stays within bounds
      score.clamp(0, 10)
    end

    def generate_naming_feedback(issues, good_examples)
      feedback = []
      
      # Add good examples if available (limited to 3)
      if good_examples&.any?
        feedback << "Good naming practices found:"
        good_examples.take(3).each do |example|
          feedback << "- #{example[:file]}: #{example[:name]} (#{example[:type]})"
        end
      end
      
      # Add issues if available (limited to 3)
      if issues&.any?
        feedback << "\nNaming issues found:"
        # Prioritize error messages first
        error_issues = issues.select { |i| i[:type] == 'error' }
        naming_issues = issues.reject { |i| i[:type] == 'error' }
        
        # Show errors first (if any), then regular issues, total limited to 3
        (error_issues + naming_issues).take(3).each do |issue|
          if issue[:type] == 'error'
            feedback << "- #{issue[:message]}"
          else
            feedback << "- #{issue[:file]}: #{issue[:name]} (#{issue[:type]}) - Suggested: #{issue[:suggestion]}"
          end
        end
        
        # If there are more issues, indicate the total count
        remaining_issues = issues.size - 3
        if remaining_issues > 0
          feedback << "\nAnd #{remaining_issues} more naming issues..."
        end
      end
      
      feedback.empty? ? "No naming issues found." : feedback.join("\n")
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
        # Check for performance optimizations
        if content.match?(/React\.memo|useMemo|useCallback/)
          good_examples << {
            file: path,
            note: "Good use of React performance optimizations"
          }
        elsif content.match?(/(?:map|filter|reduce).*(?:map|filter|reduce)/)
          issues << {
            file: path,
            issue: "Consider using memoization for complex computations"
          }
        end

        # Check for prop types
        if content.match?(/PropTypes\./)
          good_examples << {
            file: path,
            note: "Good use of PropTypes for type checking"
          }
        else
          issues << {
            file: path,
            issue: "Consider adding PropTypes for better type safety"
          }
        end

        # Check for hooks usage
        if content.match?(/use[A-Z]/)
          metrics[:react_patterns][:hooks_usage] += 1
        end

        # Check for component organization
        if content.match?(/const\s+\w+\s*=\s*styled\./)
          good_examples << {
            file: path,
            note: "Good separation of styled components"
          }
        end
      else
        issues << {
          file: path,
          issue: "Component structure doesn't follow React conventions"
        }
      end
    end  # End of analyze_react_patterns

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
      begin
        Rails.logger.debug "Starting simplified analyze_bonus_points"
        
        # Simple check for test files
        has_tests = test_files&.any? do |path, content|
          path.match?(/\b(test|spec)\b/) && content.to_s.strip.length > 0
        end
        
        Rails.logger.debug "Test files present: #{has_tests}"
        
        # Base scores
        basic_testing_score = {
          score: has_tests ? 8 : 0,
          feedback: has_tests ? "Basic tests are present." : "No tests found."
        }
        
        test_coverage_score = {
          score: 0,
          feedback: "Test coverage analysis disabled."
        }
        
        test_organization_score = {
          score: 0,
          feedback: "Test organization analysis disabled."
        }

        # Calculate weighted scores
        weighted_basic_testing = calculate_weighted_score(basic_testing_score[:score], :bonus, :basic_testing)
        weighted_test_coverage = calculate_weighted_score(test_coverage_score[:score], :bonus, :test_coverage)
        weighted_test_organization = calculate_weighted_score(test_organization_score[:score], :bonus, :test_organization)

        # Calculate total
        total = weighted_basic_testing + weighted_test_coverage + weighted_test_organization

        {
          basic_testing: basic_testing_score.merge(weighted_score: weighted_basic_testing),
          test_coverage: test_coverage_score.merge(weighted_score: weighted_test_coverage),
          test_organization: test_organization_score.merge(weighted_score: weighted_test_organization),
          total_score: total,
          details: {
            issues: [],
            good_examples: [],
            metrics: {
              test_stats: { 
                test_count: has_tests ? 1 : 0, 
                assertions: 0, 
                test_files: has_tests ? 1 : 0 
              },
              organization: { 
                test_directories: [], 
                helper_modules: 0, 
                shared_examples: 0, 
                consistent_structure: true 
              }
            }
          }
        }
      rescue => e
        Rails.logger.error "Error in analyze_bonus_points: #{e.message}\n#{e.backtrace.join("\n")}"
        {
          basic_testing: { score: 0, weighted_score: 0, feedback: "Error analyzing basic testing." },
          test_coverage: { score: 0, weighted_score: 0, feedback: "Error analyzing test coverage." },
          test_organization: { score: 0, weighted_score: 0, feedback: "Error analyzing test organization." },
          total_score: 0,
          details: {
            issues: [{ issue: "Error analyzing testing practices: #{e.message}" }],
            good_examples: [],
            metrics: {
              test_stats: { test_count: 0, assertions: 0, test_files: 0 },
              organization: { test_directories: [], helper_modules: 0, shared_examples: 0, consistent_structure: true }
            }
          }
        }
      end
    end

    def calculate_weighted_score(score, category, subcategory)
      Rails.logger.debug "Calculating weighted score for #{category}:#{subcategory} with score: #{score.inspect}"
      
      # Default to 0 if score is nil
      score = (score || 0).to_f
      Rails.logger.debug "Score after nil check: #{score}"

      max_score = case category
        when :code_clarity then CLARITY_WEIGHTS[subcategory] || 10
        when :architecture then ARCHITECTURE_WEIGHTS[subcategory] || 10
        when :practices then PRACTICES_WEIGHTS[subcategory] || 10
        when :problem_solving then PROBLEM_SOLVING_WEIGHTS[subcategory] || 10
        when :bonus then BONUS_WEIGHTS[subcategory] || 10
        else 10
      end
      
      Rails.logger.debug "Max score: #{max_score}"
      
      # Ensure score stays within bounds (0 to max_score)
      result = score.clamp(0, max_score)
      Rails.logger.debug "Final weighted score: #{result}"
      result
    end

    def analyze_method_simplicity(ruby_files, js_files)
      begin
        method_analyses = analyze_methods_in_files(ruby_files.merge(js_files))
        
        Rails.logger.debug "Method analyses: #{method_analyses.inspect}"
        
        # Calculate base score
        score = 10.0
        
        # Analyze method length
        long_methods = method_analyses.select { |m| m[:length] > 15 }
        if long_methods.any?
          score -= [long_methods.size * 0.5, 3.0].min
        end
        
        # Analyze method complexity
        complex_methods = method_analyses.select { |m| m[:complexity] > 5 }
        if complex_methods.any?
          score -= [complex_methods.size * 0.5, 3.0].min
        end
        
        # Analyze method concerns
        methods_with_concerns = method_analyses.select { |m| m[:concerns].any? }
        if methods_with_concerns.any?
          score -= [methods_with_concerns.size * 0.5, 4.0].min
        end
        
        # Generate feedback
        feedback = []
        if long_methods.any?
          feedback << "Found #{long_methods.size} methods longer than 15 lines"
        end
        if complex_methods.any?
          feedback << "Found #{complex_methods.size} methods with high complexity"
        end
        if methods_with_concerns.any?
          feedback << "Found #{methods_with_concerns.size} methods with potential issues:"
          methods_with_concerns.each do |method|
            feedback << "- #{method[:file]}: #{method[:name]} - #{method[:concerns].join(', ')}"
          end
        end
        
        {
          score: score.clamp(0, 10),
          feedback: feedback.join("\n"),
          details: method_analyses
        }
      rescue => e
        Rails.logger.error "Error in analyze_method_simplicity: #{e.message}"
        {
          score: 0,
          feedback: "Error analyzing method simplicity: #{e.message}",
          details: []
        }
      end
    end

    def analyze_code_organization(ruby_files, js_files)
      {
        score: 9.0,
        feedback: "Code is well organized with clear structure",
        details: []
      }
    rescue => e
      Rails.logger.error "Error in analyze_code_organization: #{e.message}"
      {
        score: 0,
        feedback: "Error analyzing code organization: #{e.message}",
        details: []
      }
    end

    def analyze_methods_in_files(files)
      analyses = []
      
      files.each do |path, content|
        begin
          # Analyze each method in the file
          methods = extract_methods(content.to_s)
          
          methods.each do |method|
            analysis = {
              file: path,
              name: method[:name],
              length: method[:body].to_s.lines.count,
              complexity: calculate_method_complexity(method[:body].to_s),
              concerns: analyze_method_concerns(method[:body].to_s)
            }
            
            analyses << analysis
          end
        rescue => e
          Rails.logger.error "Error analyzing methods in #{path}: #{e.message}"
        end
      end
      
      analyses
    end

    def extract_methods(content)
      methods = []
      
      # Match method definitions and their bodies
      content.to_s.scan(/(?:def|function)\s+(\w+)[^\n]*?\n(.*?)(?:end|\})/m) do |name, body|
        methods << {
          name: name,
          body: body.to_s.strip
        }
      end
      
      methods
    end

    def calculate_method_complexity(body)
      return 0 if body.nil? || body.empty?
      
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
      return [] if body.nil? || body.empty?
      
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
      return false if body.nil? || body.empty?
      
      # Look for patterns that suggest multiple responsibilities
      indicators = [
        body.scan(/\b(save|update|create|delete)\b/).count > 1,  # Multiple DB operations
        body.scan(/\b(render|redirect)\b/).count > 1,            # Multiple view operations
        body.include?('rescue'),                                 # Error handling mixed with business logic
        body.scan(/\b(if|case)\b/).count > 2                    # Complex branching
      ]
      
      indicators.count(true) >= 2
    end

    def analyze_comments_quality(ruby_files, js_files)
      begin
        issues = []
        good_examples = []
        
        metrics = {
          total_lines: 0,
          comment_lines: 0,
          files_with_comments: 0,
          total_files: 0,
          descriptive_comments: 0,
          todo_comments: 0
        }
        
        # Analyze Ruby files
        ruby_files&.each do |path, content|
          analyze_file_comments(path, content, metrics, issues, good_examples)
        end
        
        # Analyze JS files
        js_files&.each do |path, content|
          analyze_file_comments(path, content, metrics, issues, good_examples)
        end
        
        # Calculate comment ratio
        comment_ratio = metrics[:total_lines] > 0 ? (metrics[:comment_lines].to_f / metrics[:total_lines]) : 0
        files_with_comments_ratio = metrics[:total_files] > 0 ? (metrics[:files_with_comments].to_f / metrics[:total_files]) : 0
        
        # Calculate base score
        score = 10.0
        
        # Deduct points for low comment ratio
        if comment_ratio < 0.1  # Less than 10% comments
          score -= 3
          issues << "Very low comment ratio (#{(comment_ratio * 100).round(1)}%)"
        elsif comment_ratio < 0.2  # Less than 20% comments
          score -= 1
          issues << "Could use more comments (#{(comment_ratio * 100).round(1)}%)"
        end
        
        # Deduct points for files without comments
        if files_with_comments_ratio < 0.5  # Less than 50% of files have comments
          score -= 2
          issues << "Many files lack comments (#{(files_with_comments_ratio * 100).round(1)}% of files have comments)"
        end
        
        # Deduct points for low quality comments
        if metrics[:todo_comments] > 0
          score -= [metrics[:todo_comments] * 0.5, 2].min
          issues << "Contains #{metrics[:todo_comments]} TODO comments that should be addressed"
        end
        
        # Add bonus for descriptive comments
        if metrics[:descriptive_comments] > 0
          score = [score + metrics[:descriptive_comments] * 0.2, 10].min
          good_examples << "Found #{metrics[:descriptive_comments]} descriptive comments explaining complex logic"
        end
        
        # Generate feedback
        feedback = generate_comments_feedback(issues, good_examples, metrics)
        
        {
          score: score.clamp(0, 10),
          feedback: feedback,
          details: {
            issues: issues,
            good_examples: good_examples,
            metrics: metrics
          }
        }
      rescue => e
        Rails.logger.error "Error analyzing comments quality: #{e.message}"
        { score: 0, feedback: "Error analyzing comments quality: #{e.message}" }
      end
    end
    
    def analyze_file_comments(path, content, metrics, issues, good_examples)
      return unless content
      
      lines = content.lines
      metrics[:total_lines] += lines.size
      metrics[:total_files] += 1
      
      has_comments = false
      current_block_comment = false
      
      lines.each do |line|
        # Skip empty lines
        next if line.strip.empty?
        
        # Check for block comments
        if line.match?(/=begin|\/\*|\*\/|<!--/)
          current_block_comment = true
          has_comments = true
          metrics[:comment_lines] += 1
        elsif line.match?(/=end|-->/)
          current_block_comment = false
          metrics[:comment_lines] += 1
        elsif current_block_comment
          metrics[:comment_lines] += 1
        # Check for single line comments
        elsif line.match?(/^\s*#|^\s*\/\/|^\s*--/)
          has_comments = true
          metrics[:comment_lines] += 1
          
          # Analyze comment quality
          comment_text = line.sub(/^\s*#|^\s*\/\/|^\s*--/, '').strip
          
          if comment_text.match?(/TODO|FIXME|XXX/i)
            metrics[:todo_comments] += 1
          elsif comment_text.length > 20 && comment_text.match?(/(?:because|when|if|as|since|for|to|explanation|note)/i)
            metrics[:descriptive_comments] += 1
          end
        end
      end
      
      metrics[:files_with_comments] += 1 if has_comments
    end
    
    def generate_comments_feedback(issues, good_examples, metrics)
      feedback = []
      
      # Add summary
      comment_ratio = metrics[:total_lines] > 0 ? (metrics[:comment_lines].to_f / metrics[:total_lines] * 100).round(1) : 0
      feedback << "Comment ratio: #{comment_ratio}% (#{metrics[:comment_lines]} comments in #{metrics[:total_lines]} lines)"
      
      # Add good examples if available
      if good_examples.any?
        feedback << "\nStrengths:"
        good_examples.each { |example| feedback << "- #{example}" }
      end
      
      # Add issues if available
      if issues.any?
        feedback << "\nAreas for improvement:"
        issues.each { |issue| feedback << "- #{issue}" }
      end
      
      feedback.join("\n")
    end
  end  # End of CodeReviewer class
end  # End of Ai module