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
puts "Clearing existing code reviews..."
CodeReview.destroy_all

# Create sample code reviews
puts "Creating sample code reviews..."

reviews = [
  {
    candidate_name: "John Smith",
    reviewer_name: "Alice Johnson",
    submission_url: "https://github.com/john-smith/weather-app",
    quality_scores: {
      "code_clarity" => 12,
      "naming_conventions" => 8,
      "code_organization" => 9
    },
    documentation_scores: {
      "setup_instructions" => 7,
      "technical_decisions" => 6,
      "assumptions" => 4
    },
    technical_scores: {
      "solution_correctness" => 13,
      "error_handling" => 4,
      "language_usage" => 4
    },
    problem_solving_scores: {
      "completeness" => 9,
      "approach" => 8
    },
    testing_scores: {
      "coverage" => 6,
      "quality" => 4,
      "edge_cases" => 2
    },
    overall_comments: "Strong implementation with good attention to code organization.",
    created_at: 2.days.ago
  },
  {
    candidate_name: "Sarah Wilson",
    reviewer_name: "Bob Miller",
    submission_url: "https://github.com/sarah-wilson/task-manager",
    quality_scores: {
      "code_clarity" => 14,
      "naming_conventions" => 9,
      "code_organization" => 10
    },
    documentation_scores: {
      "setup_instructions" => 8,
      "technical_decisions" => 7,
      "assumptions" => 5
    },
    technical_scores: {
      "solution_correctness" => 14,
      "error_handling" => 5,
      "language_usage" => 5
    },
    problem_solving_scores: {
      "completeness" => 10,
      "approach" => 9
    },
    testing_scores: {
      "coverage" => 7,
      "quality" => 5,
      "edge_cases" => 3
    },
    overall_comments: "Excellent work across all categories. Particularly strong in testing.",
    created_at: 5.days.ago
  },
  {
    candidate_name: "Mike Brown",
    reviewer_name: "Carol White",
    submission_url: "https://github.com/mike-brown/recipe-finder",
    quality_scores: {
      "code_clarity" => 8,
      "naming_conventions" => 6,
      "code_organization" => 7
    },
    documentation_scores: {
      "setup_instructions" => 5,
      "technical_decisions" => 4,
      "assumptions" => 3
    },
    technical_scores: {
      "solution_correctness" => 10,
      "error_handling" => 3,
      "language_usage" => 3
    },
    problem_solving_scores: {
      "completeness" => 7,
      "approach" => 6
    },
    testing_scores: {
      "coverage" => 4,
      "quality" => 3,
      "edge_cases" => 1
    },
    overall_comments: "Needs improvement in code organization and testing coverage.",
    created_at: 1.week.ago
  }
]

reviews.each do |review_data|
  CodeReview.create!(review_data)
end

puts "Created #{CodeReview.count} code reviews"
