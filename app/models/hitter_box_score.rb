class HitterBoxScore < ActiveRecord::Base
  belongs_to :game
  belongs_to :hitter
end
