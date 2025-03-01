class UpdateCodeReviewScores < ActiveRecord::Migration[7.0]
  def up
    # First add new columns
    add_column :code_reviews, :clarity_scores, :jsonb, default: {}, null: false
    add_column :code_reviews, :architecture_scores, :jsonb, default: {}, null: false
    add_column :code_reviews, :practices_scores, :jsonb, default: {}, null: false
    add_column :code_reviews, :bonus_scores, :jsonb, default: {}, null: false
    add_column :code_reviews, :total_score, :decimal, precision: 5, scale: 2
    add_column :code_reviews, :assessment_level, :string unless column_exists?(:code_reviews, :assessment_level)

    # Migrate existing data
    CodeReview.find_each do |review|
      review.update_columns(
        clarity_scores: {
          naming_conventions: review.quality_scores["naming_conventions"],
          code_organization: review.quality_scores["code_organization"],
          method_simplicity: review.technical_scores["solution_correctness"],
          comments_quality: review.documentation_scores["technical_decisions"]
        },
        # ... map other scores appropriately
        total_score: review.calculate_total_score,
        assessment_level: review.assessment_level
      )
    end

    # Remove old columns
    remove_column :code_reviews, :quality_scores
    remove_column :code_reviews, :documentation_scores
    remove_column :code_reviews, :technical_scores
    remove_column :code_reviews, :testing_scores
  end

  def down
    # Add back old columns
    add_column :code_reviews, :quality_scores, :jsonb, default: {}, null: false
    add_column :code_reviews, :documentation_scores, :jsonb, default: {}, null: false
    add_column :code_reviews, :technical_scores, :jsonb, default: {}, null: false
    add_column :code_reviews, :testing_scores, :jsonb, default: {}, null: false

    # Remove new columns
    remove_column :code_reviews, :clarity_scores
    remove_column :code_reviews, :architecture_scores
    remove_column :code_reviews, :practices_scores
    remove_column :code_reviews, :bonus_scores
    remove_column :code_reviews, :total_score
    remove_column :code_reviews, :assessment_level if column_exists?(:code_reviews, :assessment_level)
  end
end 