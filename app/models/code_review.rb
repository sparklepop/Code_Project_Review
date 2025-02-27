class CodeReview < ApplicationRecord
  validates :candidate_name, presence: true
  validates :submission_url, presence: true
  validates :reviewer_name, presence: true
  
  # Allow nested attributes
  accepts_nested_attributes_for :quality_scores, 
                              :documentation_scores, 
                              :technical_scores, 
                              :problem_solving_scores, 
                              :testing_scores

  # Initialize empty hashes for scores if they're nil
  after_initialize do
    self.quality_scores ||= {}
    self.documentation_scores ||= {}
    self.technical_scores ||= {}
    self.problem_solving_scores ||= {}
    self.testing_scores ||= {}
  end

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
end 