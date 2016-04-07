class PitcherStat < ActiveRecord::Base
  belongs_to :season
  belongs_to :player
  belongs_to :game
end