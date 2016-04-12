class GameDay < ActiveRecord::Base
  belongs_to :season
  has_many   :games
  def self.search(time)
  	game_day = GameDay.where(year: time.year, month: time.month, day: time.day).first
  	unless game_day
  	  game_day = GameDay.create(season_id: Season.find_by_year(time.year).id, year: time.year, month: time.month, day: time.day)
  	end
  	return game_day
  end
end
