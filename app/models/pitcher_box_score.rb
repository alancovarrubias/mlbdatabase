class PitcherBoxScore < ActiveRecord::Base
  belongs_to :game
  belongs_to :pitcher
end
