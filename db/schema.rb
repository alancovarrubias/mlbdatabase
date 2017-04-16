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

ActiveRecord::Schema.define(version: 20170416050647) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "batter_stats", force: true do |t|
    t.integer  "batter_id"
    t.string   "handedness", default: ""
    t.string   "range",      default: ""
    t.integer  "woba",       default: 0
    t.integer  "ops",        default: 0
    t.integer  "ab",         default: 0
    t.integer  "so",         default: 0
    t.integer  "bb",         default: 0
    t.integer  "sb",         default: 0
    t.float    "fb",         default: 0.0
    t.float    "gb",         default: 0.0
    t.float    "ld",         default: 0.0
    t.integer  "wrc",        default: 0
    t.integer  "obp",        default: 0
    t.integer  "slg",        default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "batter_stats", ["batter_id"], name: "index_batter_stats_on_batter_id", using: :btree

  create_table "batters", force: true do |t|
    t.integer  "team_id"
    t.integer  "game_id"
    t.integer  "player_id"
    t.integer  "season_id"
    t.boolean  "starter",    default: false
    t.integer  "lineup",     default: 0
    t.string   "position",   default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "batters", ["game_id"], name: "index_batters_on_game_id", using: :btree
  add_index "batters", ["player_id"], name: "index_batters_on_player_id", using: :btree
  add_index "batters", ["season_id"], name: "index_batters_on_season_id", using: :btree
  add_index "batters", ["team_id"], name: "index_batters_on_team_id", using: :btree

  create_table "game_days", force: true do |t|
    t.integer  "season_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "index",      default: 0
    t.date     "date"
  end

  create_table "games", force: true do |t|
    t.integer  "away_team_id"
    t.integer  "home_team_id"
    t.string   "num",             default: ""
    t.string   "time",            default: ""
    t.string   "ump",             default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "away_money_line", default: ""
    t.string   "home_money_line", default: ""
    t.string   "away_total",      default: ""
    t.string   "home_total",      default: ""
    t.integer  "game_day_id"
    t.integer  "local_hour",      default: 0
    t.string   "stadium",         default: ""
    t.integer  "away_runs"
    t.integer  "home_runs"
    t.float    "temp",            default: 0.0
    t.float    "dew",             default: 0.0
    t.float    "baro",            default: 0.0
    t.float    "humid",           default: 0.0
    t.integer  "time_order",      default: 0
  end

  add_index "games", ["game_day_id"], name: "index_games_on_game_day_id", using: :btree

  create_table "hitter_box_scores", force: true do |t|
    t.integer  "game_id"
    t.integer  "hitter_id"
    t.boolean  "home",       default: false
    t.string   "name",       default: ""
    t.integer  "BO",         default: 0
    t.integer  "PA",         default: 0
    t.integer  "H",          default: 0
    t.integer  "HR",         default: 0
    t.integer  "R",          default: 0
    t.integer  "RBI",        default: 0
    t.integer  "BB",         default: 0
    t.integer  "SO",         default: 0
    t.integer  "wOBA",       default: 0
    t.float    "pLI",        default: 0.0
    t.float    "WPA",        default: 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "innings", force: true do |t|
    t.integer  "game_id"
    t.string   "number",     default: ""
    t.string   "away",       default: ""
    t.string   "home",       default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lancers", force: true do |t|
    t.integer  "team_id"
    t.integer  "game_id"
    t.integer  "player_id"
    t.integer  "season_id"
    t.boolean  "starter",    default: false
    t.boolean  "bullpen",    default: false
    t.integer  "pitches",    default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "ip",         default: 0.0
    t.integer  "bb",         default: 0
    t.integer  "h",          default: 0
    t.integer  "r",          default: 0
    t.integer  "np",         default: 0
    t.integer  "s",          default: 0
  end

  add_index "lancers", ["game_id"], name: "index_lancers_on_game_id", using: :btree
  add_index "lancers", ["player_id"], name: "index_lancers_on_player_id", using: :btree
  add_index "lancers", ["season_id"], name: "index_lancers_on_season_id", using: :btree
  add_index "lancers", ["team_id"], name: "index_lancers_on_team_id", using: :btree

  create_table "pitcher_box_scores", force: true do |t|
    t.integer  "game_id"
    t.integer  "pitcher_id"
    t.boolean  "home",       default: false
    t.string   "name",       default: ""
    t.float    "IP",         default: 0.0
    t.integer  "TBF",        default: 0
    t.integer  "H",          default: 0
    t.integer  "HR",         default: 0
    t.integer  "ER",         default: 0
    t.integer  "BB",         default: 0
    t.integer  "SO",         default: 0
    t.float    "FIP",        default: 0.0
    t.float    "pLI",        default: 0.0
    t.float    "WPA",        default: 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pitcher_stats", force: true do |t|
    t.integer  "lancer_id"
    t.string   "handedness", default: ""
    t.string   "range",      default: ""
    t.float    "whip",       default: 0.0
    t.float    "ip",         default: 0.0
    t.integer  "so",         default: 0
    t.integer  "bb",         default: 0
    t.integer  "fip",        default: 0
    t.float    "xfip",       default: 0.0
    t.float    "kbb",        default: 0.0
    t.integer  "woba",       default: 0
    t.integer  "ops",        default: 0
    t.float    "era",        default: 0.0
    t.float    "fb",         default: 0.0
    t.float    "gb",         default: 0.0
    t.float    "ld",         default: 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "h",          default: 0
    t.float    "siera",      default: 0.0
  end

  add_index "pitcher_stats", ["lancer_id"], name: "index_pitcher_stats_on_lancer_id", using: :btree

  create_table "players", force: true do |t|
    t.integer  "team_id"
    t.string   "name",        default: ""
    t.string   "identity",    default: ""
    t.integer  "fangraph_id"
    t.string   "bathand",     default: ""
    t.string   "throwhand",   default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",      default: true
  end

  add_index "players", ["team_id"], name: "index_players_on_team_id", using: :btree

  create_table "seasons", force: true do |t|
    t.integer  "year"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "seasons_teams", force: true do |t|
    t.integer "season_id"
    t.integer "team_id"
  end

  add_index "seasons_teams", ["season_id"], name: "index_seasons_teams_on_season_id", using: :btree
  add_index "seasons_teams", ["team_id"], name: "index_seasons_teams_on_team_id", using: :btree

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
    t.string   "league",      default: ""
    t.string   "division",    default: ""
    t.string   "city",        default: ""
  end

  add_index "teams", ["abbr"], name: "index_teams_on_abbr", using: :btree
  add_index "teams", ["fangraph_id"], name: "index_teams_on_fangraph_id", using: :btree
  add_index "teams", ["game_abbr"], name: "index_teams_on_game_abbr", using: :btree
  add_index "teams", ["name"], name: "index_teams_on_name", using: :btree

  create_table "transactions", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "username",        default: ""
    t.string   "password_digest", default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "admin",           default: false
  end

  create_table "weather_sources", force: true do |t|
    t.integer  "game_id"
    t.integer  "hour",       default: 0
    t.float    "temp"
    t.float    "precip"
    t.float    "windSpd"
    t.integer  "dewPt"
    t.float    "feelsLike"
    t.float    "relHum"
    t.float    "sfcPres"
    t.float    "spcHum"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "weather_sources", ["game_id"], name: "index_weather_sources_on_game_id", using: :btree

  create_table "weathers", force: true do |t|
    t.integer  "game_id"
    t.string   "station",     default: ""
    t.integer  "hour",        default: 0
    t.string   "wind",        default: ""
    t.string   "humidity",    default: ""
    t.string   "pressure",    default: ""
    t.string   "temp",        default: ""
    t.string   "rain",        default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "dew",         default: ""
    t.string   "feel",        default: ""
    t.string   "speed",       default: ""
    t.string   "dir",         default: ""
    t.float    "air_density", default: 0.0
  end

  add_index "weathers", ["game_id"], name: "index_weathers_on_game_id", using: :btree

end
