# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Clear existing data
puts "Clearing existing reviews..."
CodeReview.destroy_all

puts "Creating sample code reviews..."

# Outstanding candidate review
CodeReview.create!(
  candidate_name: "Ada Lovelace",
  submission_url: "https://github.com/ada/outstanding-project",
  reviewer_name: "Grace Hopper",
  quality_scores: {
    code_clarity: 14,
    naming_conventions: 9,
    code_organization: 10
  },
  documentation_scores: {
    setup_instructions: 8,
    technical_decisions: 7,
    assumptions: 5
  },
  technical_scores: {
    solution_correctness: 14,
    error_handling: 5,
    language_usage: 5
  },
  problem_solving_scores: {
    completeness: 10,
    approach: 9
  },
  testing_scores: {
    coverage: 7,
    quality: 5,
    edge_cases: 3
  },
  non_working_solution: false,
  overall_comments: "Exceptional submission with clear code organization and thorough testing."
)

# Senior level candidate
CodeReview.create!(
  candidate_name: "Alan Turing",
  submission_url: "https://github.com/turing/senior-project",
  reviewer_name: "John von Neumann",
  quality_scores: {
    code_clarity: 13,
    naming_conventions: 8,
    code_organization: 9
  },
  documentation_scores: {
    setup_instructions: 7,
    technical_decisions: 6,
    assumptions: 4
  },
  technical_scores: {
    solution_correctness: 13,
    error_handling: 4,
    language_usage: 4
  },
  problem_solving_scores: {
    completeness: 9,
    approach: 8
  },
  testing_scores: {
    coverage: 6,
    quality: 4,
    edge_cases: 2
  },
  non_working_solution: false,
  overall_comments: "Strong technical implementation with good attention to code quality."
)

# Mid level candidate
CodeReview.create!(
  candidate_name: "Margaret Hamilton",
  submission_url: "https://github.com/hamilton/mid-project",
  reviewer_name: "Donald Knuth",
  quality_scores: {
    code_clarity: 11,
    naming_conventions: 7,
    code_organization: 8
  },
  documentation_scores: {
    setup_instructions: 6,
    technical_decisions: 5,
    assumptions: 4
  },
  technical_scores: {
    solution_correctness: 11,
    error_handling: 4,
    language_usage: 4
  },
  problem_solving_scores: {
    completeness: 8,
    approach: 7
  },
  testing_scores: {
    coverage: 5,
    quality: 3,
    edge_cases: 2
  },
  non_working_solution: false,
  overall_comments: "Solid implementation with room for improvement in testing."
)

# Junior level candidate
CodeReview.create!(
  candidate_name: "Linus Torvalds",
  submission_url: "https://github.com/linus/junior-project",
  reviewer_name: "Ken Thompson",
  quality_scores: {
    code_clarity: 9,
    naming_conventions: 6,
    code_organization: 7
  },
  documentation_scores: {
    setup_instructions: 5,
    technical_decisions: 4,
    assumptions: 3
  },
  technical_scores: {
    solution_correctness: 10,
    error_handling: 3,
    language_usage: 3
  },
  problem_solving_scores: {
    completeness: 7,
    approach: 6
  },
  testing_scores: {
    coverage: 4,
    quality: 2,
    edge_cases: 1
  },
  non_working_solution: false,
  overall_comments: "Shows promise but needs improvement in code organization and testing."
)

# Below requirements
CodeReview.create!(
  candidate_name: "Charles Babbage",
  submission_url: "https://github.com/babbage/project",
  reviewer_name: "Bill Gates",
  quality_scores: {
    code_clarity: 7,
    naming_conventions: 5,
    code_organization: 6
  },
  documentation_scores: {
    setup_instructions: 4,
    technical_decisions: 3,
    assumptions: 2
  },
  technical_scores: {
    solution_correctness: 8,
    error_handling: 2,
    language_usage: 2
  },
  problem_solving_scores: {
    completeness: 6,
    approach: 5
  },
  testing_scores: {
    coverage: 2,
    quality: 1,
    edge_cases: 0
  },
  non_working_solution: true,
  overall_comments: "Significant improvements needed across all areas."
)

puts "Created #{CodeReview.count} code reviews"
