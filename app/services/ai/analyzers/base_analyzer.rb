module Ai
  module Analyzers
    class BaseAnalyzer
      def analyze(files)
        raise NotImplementedError, "Subclasses must implement analyze"
      end

      protected

      def analyze_method_lengths(content)
        raise NotImplementedError, "Subclasses must implement analyze_method_lengths"
      end

      def analyze_naming_conventions(content)
        raise NotImplementedError, "Subclasses must implement analyze_naming_conventions"
      end

      def analyze_code_organization(content)
        raise NotImplementedError, "Subclasses must implement analyze_code_organization"
      end
    end
  end
end 