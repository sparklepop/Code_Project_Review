# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2024_03_19_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "code_reviews", force: :cascade do |t|
    t.string "candidate_name", null: false
    t.string "submission_url", null: false
    t.string "reviewer_name", null: false
    t.jsonb "quality_scores", default: {}, null: false
    t.jsonb "documentation_scores", default: {}, null: false
    t.jsonb "technical_scores", default: {}, null: false
    t.jsonb "problem_solving_scores", default: {}, null: false
    t.jsonb "testing_scores", default: {}, null: false
    t.boolean "non_working_solution", default: false
    t.text "overall_comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
