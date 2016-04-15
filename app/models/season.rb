class Season < ActiveRecord::Base
  has_many :game_days
  has_many :lancers
  has_many :batters
end
