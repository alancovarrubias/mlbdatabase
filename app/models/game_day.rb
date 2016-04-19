class GameDay < ActiveRecord::Base
  belongs_to :season
  has_many   :games
  def self.search(time)
  	game_day = GameDay.find_by(year: time.year, month: time.month, day: time.day)
  	unless game_day
  	  game_day = GameDay.create(season_id: Season.find_by_year(time.year).id, year: time.year, month: time.month, day: time.day)
  	end
  	return game_day
  end

  def prev_day(num_days)
  	date = Date.parse("#{self.year}-#{self.month}-#{self.day}")
  	num_days.times do
  	  date = date.prev_day
  	end
  	return GameDay.find_by(year: date.year, month: date.month, day: date.day)
  end


end
