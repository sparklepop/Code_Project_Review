class CreateCodeReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :code_reviews do |t|
      t.string :repository_url, null: false
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
      t.text :error_message
      t.integer :status, default: 0, null: false
      t.jsonb :clarity_scores, default: {}
      t.jsonb :architecture_scores, default: {}
      t.jsonb :practices_scores, default: {}
      t.jsonb :bonus_scores, default: {}
      t.decimal :total_score
      
      t.timestamps
    end
    
    add_index :code_reviews, :repository_url
    add_index :code_reviews, :status
  end
end 