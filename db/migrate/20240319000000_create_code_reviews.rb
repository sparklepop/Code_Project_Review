class CreateCodeReviews < ActiveRecord::Migration[7.0]
  def change
    create_table :code_reviews do |t|
      t.string :candidate_name, null: false
      t.string :submission_url, null: false
      t.string :reviewer_name, null: false
      t.json :quality_scores
      t.json :documentation_scores
      t.json :technical_scores
      t.json :problem_solving_scores
      t.json :testing_scores
      t.boolean :non_working_solution, default: false
      t.text :overall_comments
      
      t.timestamps
    end
  end
end 