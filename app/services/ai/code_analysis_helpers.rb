module Ai
  module CodeAnalysisHelpers
    def analyze_method_lengths(path, content)
      # Parse Ruby code and analyze method lengths
      ast = Parser::CurrentRuby.parse(content)
      method_nodes = find_method_nodes(ast)
      
      method_nodes.each do |node|
        length = count_lines(node)
        if length > 20
          @clarity_reasons << "#{path}: Method '#{node.children[0]}' is too long (#{length} lines)"
        end
      end
    end

    def analyze_method_complexity(path, content)
      # Calculate cyclomatic complexity
    end

    def analyze_single_responsibility(path, content)
      # Check if methods follow SRP
    end

    # ... more analysis helpers ...
  end
end 