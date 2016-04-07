class Season < ActiveRecord::Base
  has_many :game_days
  has_many :pitcher_stats
  has_many :batter_stats
end
