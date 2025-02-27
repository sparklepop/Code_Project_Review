class CreateCodeReviews < ActiveRecord::Migration[7.0]
  def change
    create_table :code_reviews do |t|
      t.string :candidate_name, null: false
      t.string :submission_url, null: false
      t.string :reviewer_name, null: false
      t.jsonb :quality_scores, default: {}, null: false
      t.jsonb :documentation_scores, default: {}, null: false
      t.jsonb :technical_scores, default: {}, null: false
      t.jsonb :problem_solving_scores, default: {}, null: false
      t.jsonb :testing_scores, default: {}, null: false
      t.boolean :non_working_solution, default: false
      t.text :overall_comments
      
      t.timestamps
    end
  end
end 