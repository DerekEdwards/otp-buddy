# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20200917195241) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "itineraries", force: :cascade do |t|
    t.integer  "request_id"
    t.integer  "duration"
    t.integer  "walk_time"
    t.integer  "transit_time"
    t.integer  "wait_time"
    t.float    "walk_distance"
    t.integer  "transfers"
    t.text     "json_legs"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer  "server_status"
    t.text     "fare"
  end

  add_index "itineraries", ["request_id"], name: "idx_itins_on_request_id", using: :btree

  create_table "landmarks", force: :cascade do |t|
    t.string   "name"
    t.string   "address"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "lat"
    t.string   "lng"
    t.boolean  "old"
    t.string   "landmark_type"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "street_number"
    t.string   "route"
    t.string   "stop_code"
    t.text     "types"
    t.text     "google_place_id"
  end

  create_table "places", force: :cascade do |t|
    t.string   "lat",                    null: false
    t.string   "lng",                    null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "street_address"
    t.string   "route"
    t.string   "street_number"
    t.string   "address"
    t.string   "state"
    t.string   "city"
    t.string   "zip"
    t.string   "raw_address"
    t.string   "name"
    t.string   "stop_code"
    t.text     "types"
    t.text     "address_components_raw"
    t.text     "google_place_id"
  end

  create_table "requests", force: :cascade do |t|
    t.text     "otp_request"
    t.text     "otp_response_body"
    t.string   "otp_response_code"
    t.string   "otp_response_message"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.integer  "trip_id"
    t.string   "trip_type"
  end

  add_index "requests", ["trip_id"], name: "index_requests_on_trip_id", using: :btree

  create_table "settings", force: :cascade do |t|
    t.string   "key",        null: false
    t.text     "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trips", force: :cascade do |t|
    t.boolean  "arrive_by",                     default: true,   null: false
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
    t.integer  "origin_id"
    t.integer  "destination_id"
    t.string   "token"
    t.string   "optimize",                      default: "TIME"
    t.float    "max_walk_miles"
    t.integer  "max_walk_seconds"
    t.float    "walk_mph"
    t.float    "max_bike_miles"
    t.integer  "num_itineraries",               default: 3
    t.integer  "min_transfer_seconds"
    t.integer  "max_transfer_seconds"
    t.string   "source_tag"
    t.datetime "scheduled_time"
    t.string   "banned_routes"
    t.string   "preferred_routes"
    t.string   "locale",                        default: "en"
    t.boolean  "flex_use_reservation_services", default: true
    t.boolean  "flex_use_eligibility_services", default: true
    t.integer  "max_pretransit_time",           default: 1800
  end

  add_index "trips", ["destination_id"], name: "index_trips_on_destination_id", using: :btree
  add_index "trips", ["origin_id"], name: "index_trips_on_origin_id", using: :btree

  add_foreign_key "itineraries", "requests"
  add_foreign_key "requests", "trips"
  add_foreign_key "trips", "places", column: "destination_id"
  add_foreign_key "trips", "places", column: "origin_id"
end
