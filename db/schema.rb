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

ActiveRecord::Schema[8.1].define(version: 2026_05_03_090556) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "record_id", default: "", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "attendance_date_options", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "attendance_list_id", limit: 36, null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.datetime "updated_at", null: false
    t.index ["attendance_list_id"], name: "index_attendance_date_options_on_attendance_list_id"
  end

  create_table "attendance_date_selections", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "attendance_date_option_id", limit: 36, null: false
    t.string "attendance_entry_id", limit: 36, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attendance_entry_id", "attendance_date_option_id"], name: "idx_date_selections_unique", unique: true
    t.index ["attendance_entry_id"], name: "index_attendance_date_selections_on_attendance_entry_id"
  end

  create_table "attendance_entries", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "attendance_list_id", limit: 36, null: false
    t.string "child_id", limit: 36, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_id", limit: 36, null: false
    t.index ["attendance_list_id", "child_id"], name: "idx_entries_unique", unique: true
    t.index ["attendance_list_id"], name: "index_attendance_entries_on_attendance_list_id"
  end

  create_table "attendance_lists", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by_id", limit: 36, null: false
    t.datetime "deadline"
    t.text "description"
    t.string "event_id", limit: 36
    t.string "group_id", limit: 36, null: false
    t.string "kindergarten_year_id", limit: 36, null: false
    t.string "mode", default: "general", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_attendance_lists_on_group_id"
    t.index ["kindergarten_year_id"], name: "index_attendance_lists_on_kindergarten_year_id"
  end

  create_table "calendar_event_groups", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "calendar_event_id", limit: 36, null: false
    t.datetime "created_at", null: false
    t.string "group_id", limit: 36, null: false
    t.datetime "updated_at", null: false
    t.index ["calendar_event_id", "group_id"], name: "idx_cal_event_groups_unique", unique: true
    t.index ["calendar_event_id"], name: "index_calendar_event_groups_on_calendar_event_id"
  end

  create_table "calendar_events", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.boolean "all_day", default: true, null: false
    t.datetime "created_at", null: false
    t.string "created_by_id", limit: 36, null: false
    t.text "description"
    t.string "event_type", default: "event", null: false
    t.string "kindergarten_year_id", limit: 36, null: false
    t.string "location"
    t.date "start_date", null: false
    t.string "start_time"
    t.string "status", default: "aktiv", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_calendar_events_on_created_by_id"
    t.index ["kindergarten_year_id"], name: "index_calendar_events_on_kindergarten_year_id"
    t.index ["start_date"], name: "index_calendar_events_on_start_date"
  end

  create_table "children", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.date "date_of_birth", null: false
    t.string "first_name", null: false
    t.string "group_id", limit: 36, null: false
    t.string "health_insurer"
    t.string "insurance_number"
    t.string "kindergarten_year_id", limit: 36, null: false
    t.string "last_name", null: false
    t.string "nickname"
    t.boolean "photo_consent"
    t.datetime "photo_consent_updated_at"
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_children_on_group_id"
    t.index ["kindergarten_year_id"], name: "index_children_on_kindergarten_year_id"
  end

  create_table "emergency_contacts", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "child_id", limit: 36, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "phone", null: false
    t.integer "position", default: 0, null: false
    t.string "relationship", null: false
    t.datetime "updated_at", null: false
    t.index ["child_id", "position"], name: "index_emergency_contacts_on_child_id_and_position"
    t.index ["child_id"], name: "index_emergency_contacts_on_child_id"
  end

  create_table "galleries", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by_id", limit: 36, null: false
    t.text "description"
    t.date "event_date"
    t.string "event_id", limit: 36
    t.string "kindergarten_year_id", limit: 36, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_galleries_on_created_by_id"
    t.index ["event_id"], name: "index_galleries_on_event_id"
    t.index ["kindergarten_year_id"], name: "index_galleries_on_kindergarten_year_id"
  end

  create_table "gallery_groups", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "gallery_id", limit: 36, null: false
    t.string "group_id", limit: 36, null: false
    t.datetime "updated_at", null: false
    t.index ["gallery_id", "group_id"], name: "index_gallery_groups_on_gallery_id_and_group_id", unique: true
    t.index ["gallery_id"], name: "index_gallery_groups_on_gallery_id"
    t.index ["group_id"], name: "index_gallery_groups_on_group_id"
  end

  create_table "groups", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "inbox_entries", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "message_id", limit: 36, null: false
    t.datetime "read_at"
    t.datetime "updated_at", null: false
    t.string "user_id", limit: 36, null: false
    t.index ["message_id", "user_id"], name: "index_inbox_entries_on_message_id_and_user_id", unique: true
    t.index ["message_id"], name: "index_inbox_entries_on_message_id"
    t.index ["user_id"], name: "index_inbox_entries_on_user_id"
  end

  create_table "kindergarten_years", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.datetime "created_at", null: false
    t.date "end_date", null: false
    t.string "label", null: false
    t.date "start_date", null: false
    t.datetime "updated_at", null: false
  end

  create_table "meal_entries", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by_id", null: false
    t.date "date", null: false
    t.string "group_id", null: false
    t.string "kindergarten_year_id", null: false
    t.string "meal", null: false
    t.text "notes"
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_meal_entries_on_created_by_id"
    t.index ["date", "group_id"], name: "index_meal_entries_on_date_and_group_id", unique: true
    t.index ["group_id"], name: "index_meal_entries_on_group_id"
    t.index ["kindergarten_year_id"], name: "index_meal_entries_on_kindergarten_year_id"
  end

  create_table "medical_notes", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "child_id", limit: 36, null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "note_type", null: false
    t.datetime "updated_at", null: false
    t.index ["child_id"], name: "index_medical_notes_on_child_id"
  end

  create_table "message_groups", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "group_id", limit: 36, null: false
    t.string "message_id", limit: 36, null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_message_groups_on_group_id"
    t.index ["message_id", "group_id"], name: "index_message_groups_on_message_id_and_group_id", unique: true
    t.index ["message_id"], name: "index_message_groups_on_message_id"
  end

  create_table "messages", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "sent_by_id", limit: 36, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["sent_by_id"], name: "index_messages_on_sent_by_id"
  end

  create_table "parent_children", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "child_id", limit: 36, null: false
    t.datetime "created_at", null: false
    t.text "note"
    t.datetime "updated_at", null: false
    t.string "user_id", limit: 36, null: false
    t.index ["child_id"], name: "index_parent_children_on_child_id"
    t.index ["user_id", "child_id"], name: "index_parent_children_on_user_id_and_child_id", unique: true
  end

  create_table "poll_options", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "label", null: false
    t.string "poll_id", limit: 36, null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["poll_id"], name: "index_poll_options_on_poll_id"
  end

  create_table "polls", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by_id", limit: 36, null: false
    t.datetime "deadline"
    t.text "description"
    t.string "event_id", limit: 36
    t.string "group_id", limit: 36, null: false
    t.string "kindergarten_year_id", limit: 36, null: false
    t.string "poll_type", default: "single", null: false
    t.string "status", default: "open", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_polls_on_created_by_id"
    t.index ["event_id"], name: "index_polls_on_event_id"
    t.index ["group_id"], name: "index_polls_on_group_id"
    t.index ["kindergarten_year_id"], name: "index_polls_on_kindergarten_year_id"
  end

  create_table "sessions", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.string "user_id", limit: 36, null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "shopping_items", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "completed_at"
    t.string "completed_by_id", limit: 36
    t.datetime "created_at", null: false
    t.boolean "done", default: false, null: false
    t.string "name", null: false
    t.text "note"
    t.integer "position", default: 0, null: false
    t.string "quantity"
    t.string "shopping_list_id", limit: 36, null: false
    t.datetime "updated_at", null: false
    t.index ["shopping_list_id", "position"], name: "index_shopping_items_on_shopping_list_id_and_position"
    t.index ["shopping_list_id"], name: "index_shopping_items_on_shopping_list_id"
  end

  create_table "shopping_lists", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by_id", limit: 36, null: false
    t.text "description"
    t.date "event_date", null: false
    t.string "event_id", limit: 36
    t.string "group_id", limit: 36, null: false
    t.string "kindergarten_year_id", limit: 36, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_shopping_lists_on_group_id"
    t.index ["kindergarten_year_id"], name: "index_shopping_lists_on_kindergarten_year_id"
  end

  create_table "users", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.boolean "email_invalid", default: false, null: false
    t.string "first_name"
    t.string "ical_token"
    t.datetime "invitation_sent_at"
    t.string "invited_by_id"
    t.string "last_name"
    t.datetime "locked_at"
    t.integer "magic_link_token_version", default: 0, null: false
    t.string "password_digest", null: false
    t.string "phone"
    t.string "role", default: "caretaker", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["ical_token"], name: "index_users_on_ical_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
  end

  create_table "votes", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "poll_option_id", limit: 36, null: false
    t.datetime "updated_at", null: false
    t.string "user_id", limit: 36, null: false
    t.index ["poll_option_id", "user_id"], name: "index_votes_on_poll_option_id_and_user_id", unique: true
    t.index ["poll_option_id"], name: "index_votes_on_poll_option_id"
    t.index ["user_id"], name: "index_votes_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "galleries", "kindergarten_years"
  add_foreign_key "galleries", "users", column: "created_by_id"
  add_foreign_key "gallery_groups", "galleries"
  add_foreign_key "gallery_groups", "groups"
  add_foreign_key "inbox_entries", "messages"
  add_foreign_key "inbox_entries", "users"
  add_foreign_key "meal_entries", "groups"
  add_foreign_key "meal_entries", "kindergarten_years"
  add_foreign_key "meal_entries", "users", column: "created_by_id"
  add_foreign_key "message_groups", "groups"
  add_foreign_key "message_groups", "messages"
  add_foreign_key "messages", "users", column: "sent_by_id"
  add_foreign_key "poll_options", "polls"
  add_foreign_key "polls", "groups"
  add_foreign_key "polls", "kindergarten_years"
  add_foreign_key "polls", "users", column: "created_by_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "votes", "poll_options"
  add_foreign_key "votes", "users"
end
