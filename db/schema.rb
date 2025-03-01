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

ActiveRecord::Schema[8.0].define(version: 2024_03_01_030000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "code_reviews", force: :cascade do |t|
    t.string "repository_url", null: false
    t.string "candidate_name", null: false
    t.string "reviewer_name", null: false
    t.jsonb "problem_solving_scores", default: {}, null: false
    t.boolean "non_working_solution", default: false
    t.text "overall_comments"
    t.text "error_message"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "clarity_scores", default: {}, null: false
    t.jsonb "architecture_scores", default: {}, null: false
    t.jsonb "practices_scores", default: {}, null: false
    t.jsonb "bonus_scores", default: {}, null: false
    t.decimal "total_score", precision: 5, scale: 2
    t.string "assessment_level"
    t.index ["repository_url"], name: "index_code_reviews_on_repository_url"
    t.index ["status"], name: "index_code_reviews_on_status"
  end
end
