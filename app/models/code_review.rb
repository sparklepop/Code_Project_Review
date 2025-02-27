class CodeReview < ApplicationRecord
  validates :candidate_name, presence: true
  validates :submission_url, presence: true
  validates :reviewer_name, presence: true
  
  # Add accessors for score attributes
  store_accessor :quality_scores, :code_clarity, :naming_conventions, :code_organization
  store_accessor :documentation_scores, :setup_instructions, :technical_decisions, :assumptions
  store_accessor :technical_scores, :solution_correctness, :error_handling, :language_usage
  store_accessor :problem_solving_scores, :completeness, :approach
  store_accessor :testing_scores, :coverage, :quality, :edge_cases

  # Initialize and convert scores before save
  before_validation :process_scores

  # Score calculation methods
  def calculate_quality_score
    return 0 unless quality_scores
    quality_scores.values.map(&:to_i).sum
  end

  def calculate_documentation_score
    return 0 unless documentation_scores
    documentation_scores.values.map(&:to_i).sum
  end

  def calculate_technical_score
    return 0 unless technical_scores
    technical_scores.values.map(&:to_i).sum
  end

  def calculate_problem_solving_score
    return 0 unless problem_solving_scores
    problem_solving_scores.values.map(&:to_i).sum
  end

  def calculate_testing_bonus
    return 0 unless testing_scores
    testing_scores.values.map(&:to_i).sum
  end

  def calculate_total_score
    base_score = [
      calculate_quality_score,
      calculate_documentation_score,
      calculate_technical_score,
      calculate_problem_solving_score
    ].sum

    bonus = calculate_testing_bonus
    deduction = non_working_solution? ? 30 : 0

    base_score + bonus - deduction
  end

  def assessment_level
    case calculate_total_score
    when 95..115 then "Outstanding - Strong Senior+ candidate"
    when 85..94 then "Excellent - Senior candidate"
    when 75..84 then "Good - Mid-level candidate"
    when 65..74 then "Fair - Junior candidate"
    else "Does not meet requirements"
    end
  end

  private

  def process_scores
    puts "\nProcessing scores before validation:"
    puts "Before: #{attributes.slice(*score_attributes).inspect}"
    
    score_attributes.each do |attr|
      current_scores = send(attr)
      
      # Convert the scores to a hash if needed
      scores = case current_scores
              when String
                JSON.parse(current_scores) rescue {}
              when ActionController::Parameters
                current_scores.to_unsafe_h
              when Hash
                current_scores
              else
                {}
              end
      
      # Ensure all values are integers
      scores.transform_values! { |v| v.to_i }
      
      # Update the attribute
      send("#{attr}=", scores)
    end
    
    puts "After: #{attributes.slice(*score_attributes).inspect}"
  end

  def score_attributes
    %w[quality_scores documentation_scores technical_scores problem_solving_scores testing_scores]
  end
end 