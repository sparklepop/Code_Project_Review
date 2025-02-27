FactoryBot.define do
  factory :code_review do
    candidate_name { Faker::Name.name }
    submission_url { Faker::Internet.url }
    reviewer_name { Faker::Name.name }
    non_working_solution { false }
    overall_comments { Faker::Lorem.paragraph }

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