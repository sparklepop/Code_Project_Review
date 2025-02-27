# frozen_string_literal: true

class AddScoreReasoningToCodeReviews < ActiveRecord::Migration[7.1]
  def change
    # No need for a new column since we're storing in the existing JSON columns
    # Just update the model to handle the new attributes
  end
end 