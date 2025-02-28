# frozen_string_literal: true

module Ai
  class CodeAnalyzer
    LONG_METHOD_THRESHOLD = 20
    LONG_LINE_THRESHOLD = 100
    MAX_INDENTATION_LEVEL = 3

    def initialize(files)
      @files = files
      @clarity_reasons = []
      @naming_reasons = []
      @organization_reasons = []
    end

    def analyze
      Rails.logger.debug "Starting analysis of #{@files.keys.count} files"
      
      @files.each do |path, file|
        analyze_file(path, file[:content])
      end

      {
        quality_scores: calculate_quality_scores,
        documentation_scores: calculate_documentation_scores,
        technical_scores: calculate_technical_scores,
        problem_solving_scores: calculate_problem_solving_scores,
        testing_scores: calculate_testing_scores,
        issues: {
          clarity: @clarity_reasons,
          naming: @naming_reasons,
          organization: @organization_reasons
        }
      }
    end

    private

    def analyze_file(path, content)
      Rails.logger.debug "Analyzing #{path}"
      lines = content.lines

      check_method_length(path, lines)
      check_line_length(path, lines)
      check_indentation(path, lines)
      check_naming(path, content)
      check_organization(path, content)
    end

    def check_method_length(path, lines)
      in_method = false
      method_lines = 0
      method_name = nil

      lines.each do |line|
        if line =~ /\bdef\s+(\w+)/
          in_method = true
          method_name = $1
          method_lines = 0
        elsif line =~ /\bend\b/ && in_method
          if method_lines > LONG_METHOD_THRESHOLD
            @clarity_reasons << "#{path}: Method '#{method_name}' is too long (#{method_lines} lines)"
          end
          in_method = false
        elsif in_method
          method_lines += 1
        end
      end
    end

    def check_line_length(path, lines)
      long_lines = lines.each_with_index.select { |line, _| line.length > LONG_LINE_THRESHOLD }
      if long_lines.any?
        @clarity_reasons << "#{path}: Contains #{long_lines.count} lines longer than #{LONG_LINE_THRESHOLD} characters"
      end
    end

    def check_indentation(path, lines)
      max_depth = lines.map { |line| line[/^\s*/].length / 2 }.max
      if max_depth > MAX_INDENTATION_LEVEL
        @organization_reasons << "#{path}: Maximum nesting depth of #{max_depth} exceeds recommended #{MAX_INDENTATION_LEVEL}"
      end
    end

    def check_naming(path, content)
      # Check for single-letter variables (except common iterators)
      variables = content.scan(/\b[a-z_]+\b/)
      unclear = variables.select { |name| name.length < 2 && !%w[i j k v p].include?(name) }
      if unclear.any?
        @naming_reasons << "#{path}: Contains unclear variable names: #{unclear.join(', ')}"
      end
    end

    def check_organization(path, content)
      if content.lines.count > 300
        @organization_reasons << "#{path}: File is too long (#{content.lines.count} lines)"
      end
    end

    def calculate_quality_scores
      {
        code_clarity: score_from_issues(@clarity_reasons, 15),
        naming_conventions: score_from_issues(@naming_reasons, 10),
        code_organization: score_from_issues(@organization_reasons, 10)
      }
    end

    def calculate_documentation_scores
      {
        setup_instructions: 7,
        technical_decisions: 6,
        assumptions: 4
      }
    end

    def calculate_technical_scores
      {
        solution_correctness: 13,
        error_handling: 4,
        language_usage: 4
      }
    end

    def calculate_problem_solving_scores
      {
        completeness: 9,
        approach: 8
      }
    end

    def calculate_testing_scores
      {
        coverage: 6,
        quality: 4,
        edge_cases: 2
      }
    end

    def score_from_issues(issues, base_score)
      deductions = issues.length * 2
      [base_score - deductions, 0].max
    end
  end
end 