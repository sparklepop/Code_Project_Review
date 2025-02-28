# frozen_string_literal: true

module Ai
  module Analyzers
    class GenericAnalyzer < BaseAnalyzer
      LONG_METHOD_THRESHOLD = 20
      LONG_LINE_THRESHOLD = 100
      MAX_INDENTATION_LEVEL = 3

      AnalysisResult = Struct.new(:clarity_score, :naming_score, :organization_score,
                                 :clarity_reasons, :naming_reasons, :organization_reasons)

      def analyze(files)
        @clarity_reasons = []
        @naming_reasons = []
        @organization_reasons = []

        Rails.logger.debug "Analyzing #{files.keys.count} files"
        
        files.each do |path, file|
          Rails.logger.debug "Analyzing file: #{path}"
          analyze_file(path, file[:content])
        end

        Rails.logger.debug "Found issues:"
        Rails.logger.debug "Clarity: #{@clarity_reasons}"
        Rails.logger.debug "Naming: #{@naming_reasons}"
        Rails.logger.debug "Organization: #{@organization_reasons}"

        AnalysisResult.new(
          calculate_clarity_score,
          calculate_naming_score,
          calculate_organization_score,
          @clarity_reasons,
          @naming_reasons,
          @organization_reasons
        )
      end

      private

      def analyze_file(path, content)
        lines = content.lines

        analyze_method_lengths(path, lines)
        analyze_line_lengths(path, lines)
        analyze_indentation_depth(path, lines)
        analyze_naming_patterns(path, content)
        analyze_file_organization(path, content)
      end

      def analyze_method_lengths(path, lines)
        # Look for method-like patterns (def, function, etc.)
        method_blocks = find_code_blocks(lines)
        
        method_blocks.each do |name, length|
          if length > LONG_METHOD_THRESHOLD
            @clarity_reasons << "#{path}: Method '#{name}' is too long (#{length} lines)"
          end
        end
      end

      def analyze_line_lengths(path, lines)
        long_lines = lines.each_with_index.select { |line, _| line.length > LONG_LINE_THRESHOLD }
        if long_lines.any?
          @clarity_reasons << "#{path}: Contains #{long_lines.count} lines longer than #{LONG_LINE_THRESHOLD} characters"
        end
      end

      def analyze_indentation_depth(path, lines)
        max_depth = lines.map { |line| indentation_level(line) }.max
        if max_depth > MAX_INDENTATION_LEVEL
          @organization_reasons << "#{path}: Maximum nesting depth of #{max_depth} exceeds recommended #{MAX_INDENTATION_LEVEL}"
        end
      end

      def analyze_naming_patterns(path, content)
        # Look for unclear names (too short, cryptic, etc.)
        unclear_names = find_unclear_names(content)
        if unclear_names.any?
          @naming_reasons << "#{path}: Contains unclear names: #{unclear_names.join(', ')}"
        end
      end

      def analyze_file_organization(path, content)
        # Check file length
        if content.lines.count > 300
          @organization_reasons << "#{path}: File is too long (#{content.lines.count} lines)"
        end

        # Check for logical grouping of code
        unless has_logical_grouping?(content)
          @organization_reasons << "#{path}: Code sections could be better organized"
        end
      end

      def find_code_blocks(lines)
        blocks = {}
        current_block = nil
        block_lines = 0

        lines.each do |line|
          if block_start?(line)
            current_block = extract_block_name(line)
            block_lines = 1
          elsif block_end?(line) && current_block
            blocks[current_block] = block_lines
            current_block = nil
          elsif current_block
            block_lines += 1
          end
        end

        blocks
      end

      def block_start?(line)
        line =~ /\b(def|function|class|module|interface)\b/
      end

      def block_end?(line)
        line =~ /\b(end|})\b/
      end

      def extract_block_name(line)
        line[/\b(def|function|class|module|interface)\s+([^\s({]+)/, 2]
      end

      def indentation_level(line)
        line[/^\s*/].length / 2
      end

      def find_unclear_names(content)
        # Look for single-letter variables (except common iterators)
        variables = content.scan(/\b[a-z_]+\b/)
        variables.select { |name| name.length < 2 && !%w[i j k v p].include?(name) }
      end

      def has_logical_grouping?(content)
        # Look for common grouping patterns (comments, blank lines between sections)
        sections = content.split(/\n\s*\n/)
        sections.length > 1
      end

      def calculate_clarity_score
        base_score = 15
        deductions = @clarity_reasons.length * 2
        [base_score - deductions, 0].max
      end

      def calculate_naming_score
        base_score = 10
        deductions = @naming_reasons.length * 2
        [base_score - deductions, 0].max
      end

      def calculate_organization_score
        base_score = 10
        deductions = @organization_reasons.length * 2
        [base_score - deductions, 0].max
      end
    end
  end
end 