FactoryBot.define do
  factory :code_review do
    candidate_name { "John Doe" }
    reviewer_name { "Jane Smith" }
    submission_url { "https://github.com/example/project" }
    quality_scores { { 
      "code_clarity" => "12",
      "naming_conventions" => "8",
      "code_organization" => "9"
    } }
    documentation_scores { {
      "setup_instructions" => "7",
      "technical_decisions" => "6",
      "assumptions" => "4"
    } }
    technical_scores { {
      "solution_correctness" => "13",
      "error_handling" => "4",
      "language_usage" => "4"
    } }
    problem_solving_scores { {
      "completeness" => "9",
      "approach" => "8"
    } }
    testing_scores { {
      "coverage" => "6",
      "quality" => "4",
      "edge_cases" => "2"
    } }
    non_working_solution { false }
    overall_comments { "Good work overall with attention to detail." }

    trait :outstanding do
      quality_scores { {
        code_clarity: 14,
        naming_conventions: 9,
        code_organization: 10
      } }
      documentation_scores { {
        setup_instructions: 8,
        technical_decisions: 7,
        assumptions: 5
      } }
      technical_scores { {
        solution_correctness: 14,
        error_handling: 5,
        language_usage: 5
      } }
      problem_solving_scores { {
        completeness: 10,
        approach: 9
      } }
      testing_scores { {
        coverage: 7,
        quality: 5,
        edge_cases: 3
      } }
    end

    trait :non_working do
      non_working_solution { true }
    end
  end
end 