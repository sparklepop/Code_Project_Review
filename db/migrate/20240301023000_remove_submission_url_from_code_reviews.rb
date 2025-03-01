class RemoveSubmissionUrlFromCodeReviews < ActiveRecord::Migration[7.0]
  def change
    remove_column :code_reviews, :submission_url, :string, null: false
  end
end 