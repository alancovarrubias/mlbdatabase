class BatterStat < ActiveRecord::Base
  belongs_to :season
  belongs_to :player
  belongs_to :game
end
