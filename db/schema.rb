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

ActiveRecord::Schema.define(version: 20150701205156) do

  create_table "games", force: true do |t|
    t.integer  "away_team_id"
    t.integer  "home_team_id"
    t.string   "year",            default: ""
    t.string   "month",           default: ""
    t.string   "day",             default: ""
    t.string   "num",             default: ""
    t.string   "time",            default: ""
    t.string   "ump",             default: ""
    t.string   "wind_1",          default: ""
    t.string   "humidity_1",      default: ""
    t.string   "pressure_1",      default: ""
    t.string   "temperature_1",   default: ""
    t.string   "precipitation_1", default: ""
    t.string   "wind_2",          default: ""
    t.string   "humidity_2",      default: ""
    t.string   "pressure_2",      default: ""
    t.string   "temperature_2",   default: ""
    t.string   "precipitation_2", default: ""
    t.string   "wind_3",          default: ""
    t.string   "humidity_3",      default: ""
    t.string   "pressure_3",      default: ""
    t.string   "temperature_3",   default: ""
    t.string   "precipitation_3", default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "hitters", force: true do |t|
    t.integer  "team_id"
    t.integer  "game_id"
    t.string   "name",                       default: ""
    t.string   "alias",                      default: ""
    t.integer  "fangraph_id",                default: 0
    t.string   "bathand",                    default: ""
    t.string   "throwhand",                  default: ""
    t.integer  "lineup",                     default: 0
    t.boolean  "starter",                    default: false
    t.integer  "SB_L",                       default: 0
    t.integer  "wOBA_L",                     default: 0
    t.integer  "OBP_L",                      default: 0
    t.integer  "SLG_L",                      default: 0
    t.integer  "AB_L",                       default: 0
    t.integer  "BB_L",                       default: 0
    t.integer  "SO_L",                       default: 0
    t.float    "LD_L",            limit: 24, default: 0.0
    t.integer  "wRC_L",                      default: 0
    t.integer  "SB_R",                       default: 0
    t.integer  "wOBA_R",                     default: 0
    t.integer  "OBP_R",                      default: 0
    t.integer  "SLG_R",                      default: 0
    t.integer  "AB_R",                       default: 0
    t.integer  "BB_R",                       default: 0
    t.integer  "SO_R",                       default: 0
    t.float    "LD_R",            limit: 24, default: 0.0
    t.integer  "wRC_R",                      default: 0
    t.integer  "wOBA_14",                    default: 0
    t.integer  "OBP_14",                     default: 0
    t.integer  "SLG_14",                     default: 0
    t.integer  "AB_14",                      default: 0
    t.integer  "BB_14",                      default: 0
    t.integer  "SB_14",                      default: 0
    t.integer  "SO_14",                      default: 0
    t.float    "LD_14",           limit: 24, default: 0.0
    t.integer  "wRC_14",                     default: 0
    t.integer  "SB_previous_L",              default: 0
    t.integer  "wOBA_previous_L",            default: 0
    t.integer  "OBP_previous_L",             default: 0
    t.integer  "SLG_previous_L",             default: 0
    t.integer  "AB_previous_L",              default: 0
    t.integer  "BB_previous_L",              default: 0
    t.integer  "SO_previous_L",              default: 0
    t.float    "LD_previous_L",   limit: 24, default: 0.0
    t.integer  "wRC_previous_L",             default: 0
    t.integer  "SB_previous_R",              default: 0
    t.integer  "wOBA_previous_R",            default: 0
    t.integer  "OBP_previous_R",             default: 0
    t.integer  "SLG_previous_R",             default: 0
    t.integer  "AB_previous_R",              default: 0
    t.integer  "BB_previous_R",              default: 0
    t.integer  "SO_previous_R",              default: 0
    t.float    "LD_previous_R",   limit: 24, default: 0.0
    t.integer  "wRC_previous_R",             default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "hitters", ["alias"], name: "index_hitters_on_alias", using: :btree
  add_index "hitters", ["fangraph_id"], name: "index_hitters_on_fangraph_id", using: :btree
  add_index "hitters", ["name"], name: "index_hitters_on_name", using: :btree

  create_table "pitchers", force: true do |t|
    t.integer  "team_id"
    t.integer  "game_id"
    t.string   "name",                        default: ""
    t.string   "alias",                       default: ""
    t.integer  "fangraph_id",                 default: 0
    t.string   "bathand",                     default: ""
    t.string   "throwhand",                   default: ""
    t.boolean  "starter",                     default: false
    t.boolean  "bullpen",                     default: false
    t.integer  "one",                         default: 0
    t.integer  "two",                         default: 0
    t.integer  "three",                       default: 0
    t.integer  "FIP",                         default: 0
    t.float    "LD_L",             limit: 24, default: 0.0
    t.float    "WHIP_L",           limit: 24, default: 0.0
    t.float    "IP_L",             limit: 24, default: 0.0
    t.integer  "SO_L",                        default: 0
    t.integer  "BB_L",                        default: 0
    t.float    "ERA_L",            limit: 24, default: 0.0
    t.integer  "wOBA_L",                      default: 0
    t.float    "FB_L",             limit: 24, default: 0.0
    t.float    "xFIP_L",           limit: 24, default: 0.0
    t.float    "KBB_L",            limit: 24, default: 0.0
    t.float    "LD_R",             limit: 24, default: 0.0
    t.float    "WHIP_R",           limit: 24, default: 0.0
    t.float    "IP_R",             limit: 24, default: 0.0
    t.integer  "SO_R",                        default: 0
    t.integer  "BB_R",                        default: 0
    t.float    "ERA_R",            limit: 24, default: 0.0
    t.integer  "wOBA_R",                      default: 0
    t.float    "FB_R",             limit: 24, default: 0.0
    t.float    "xFIP_R",           limit: 24, default: 0.0
    t.float    "KBB_R",            limit: 24, default: 0.0
    t.float    "LD_30",            limit: 24, default: 0.0
    t.float    "WHIP_30",          limit: 24, default: 0.0
    t.float    "IP_30",            limit: 24, default: 0.0
    t.integer  "SO_30",                       default: 0
    t.integer  "BB_30",                       default: 0
    t.integer  "FIP_previous",                default: 0
    t.float    "FB_previous_L",    limit: 24, default: 0.0
    t.float    "FB_previous_R",    limit: 24, default: 0.0
    t.float    "xFIP_previous_L",  limit: 24, default: 0.0
    t.float    "xFIP_previous_R",  limit: 24, default: 0.0
    t.float    "KBB_previous_L",   limit: 24, default: 0.0
    t.float    "KBB_previous_R",   limit: 24, default: 0.0
    t.integer  "wOBA_previous_L",             default: 0
    t.integer  "wOBA_previous_R",             default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "tomorrow_starter"
  end

  add_index "pitchers", ["alias"], name: "index_pitchers_on_alias", using: :btree
  add_index "pitchers", ["fangraph_id"], name: "index_pitchers_on_fangraph_id", using: :btree
  add_index "pitchers", ["name"], name: "index_pitchers_on_name", using: :btree

  create_table "teams", force: true do |t|
    t.string   "name",        default: ""
    t.string   "abbr",        default: ""
    t.string   "stadium",     default: ""
    t.string   "zipcode",     default: ""
    t.integer  "timezone",    default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "fangraph_id"
    t.string   "game_abbr"
  end

  add_index "teams", ["abbr"], name: "index_teams_on_abbr", using: :btree
  add_index "teams", ["fangraph_id"], name: "index_teams_on_fangraph_id", using: :btree
  add_index "teams", ["game_abbr"], name: "index_teams_on_game_abbr", using: :btree
  add_index "teams", ["name"], name: "index_teams_on_name", using: :btree

  create_table "users", force: true do |t|
    t.string   "username",        default: ""
    t.string   "password_digest", default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
