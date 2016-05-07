class GameDay < ActiveRecord::Base
  belongs_to :season
  has_many   :games,        dependent: :destroy
  has_many   :transactions, dependent: :destroy

  def find_index
    year * 366 + month * 31 + day 
  end

  def self.search(time)
  	game_day = GameDay.find_by(year: time.year, month: time.month, day: time.day)
  	unless game_day
  	  game_day = GameDay.create(season: Season.find_by_year(time.year), year: time.year, month: time.month, day: time.day)
      game_day.update(index: game_day.find_index)
  	end
  	return game_day
  end

  def prev_day(num_days)
  	date = Date.parse("#{year}-#{month}-#{day}")
  	num_days.times do
  	  date = date.prev_day
  	end
  	return GameDay.find_by(year: date.year, month: date.month, day: date.day)
  end

  def date
    "#{year}/#{month}/#{day}"
  end

  def is_preseason?
    if month < 4 || (month == 4 && day < 3)
      true
    end
  end

end
