class GameDay < ActiveRecord::Base
  belongs_to :season
  has_many   :games,        dependent: :destroy
  has_many   :transactions, dependent: :destroy

  def self.search(time)
    game_day = GameDay.find_by(year: time.year, month: time.month, day: time.day)
    unless game_day
      game_day = GameDay.create(season: Season.find_by_year(time.year), year: time.year, month: time.month, day: time.day)
      game_day.update(index: game_day.find_index)
    end
    game_day
  end

  def self.yesterday
    GameDay.search(Time.now.yesterday)
  end

  def self.today
    GameDay.search(Time.now)
  end

  def self.tomorrow
    GameDay.search(Time.now.tomorrow)
  end

  def create_games
    if today? || tomorrow?
      Create::Games.new.create(self)
      Create::Bullpen.new.create(self)
    end
  end

  def update_games
    if today?
      Update::Games.new.update(self)
    end
  end

  def delete_games
    games.destroy_all
  end

  def update_weather
    games.map { |game| game.create_weather }
    games.map { |game| game.update_weather }
  end

  def update_forecast
    if today? || tomorrow?
      games.map { |game| game.create_weather }
      games.map { |game| game.update_forecast }
    end
  end

  def pitcher_box_score
    Update::Pitchers.new.box_scores(self)
  end

  def time
    Time.new(year, month, day)
  end

  def find_index
    year * 366 + month * 31 + day 
  end

  def previous_days(num_days)
  	date = Date.parse("#{year}-#{month}-#{day}")
  	num_days.times do
  	  date = date.prev_day
  	end
  	GameDay.find_by(year: date.year, month: date.month, day: date.day)
  end

  def date
    "#{year}/#{month}/#{day}"
  end

  def is_preseason?
    if month < 4 || (month == 4 && day < 3)
      true
    end
  end

  def today?
    if self == GameDay.today
      true
    else
      false
    end
  end

  def tomorrow?
    if self == GameDay.tomorrow
      true
    else
      false
    end
  end

end
