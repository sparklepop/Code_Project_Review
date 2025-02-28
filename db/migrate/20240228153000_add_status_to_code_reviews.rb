class AddStatusToCodeReviews < ActiveRecord::Migration[7.0]
  def change
    add_column :code_reviews, :status, :integer, default: 0, null: false
    add_index :code_reviews, :status
  end
end 