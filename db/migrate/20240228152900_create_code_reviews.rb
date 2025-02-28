class CreateCodeReviews < ActiveRecord::Migration[7.0]
  def change
    create_table :code_reviews do |t|
      t.string :repository_url, null: false
      t.string :candidate_name, null: false
      t.string :reviewer_name, null: false
      t.string :submission_url, null: false
      t.jsonb :quality_scores
      t.jsonb :documentation_scores
      t.jsonb :technical_scores
      t.jsonb :problem_solving_scores
      t.jsonb :testing_scores
      t.text :error_message
      
      t.timestamps
    end
    
    add_index :code_reviews, :repository_url
  end
end 