class GameDay < ActiveRecord::Base
  belongs_to :season
  has_many   :games
end
