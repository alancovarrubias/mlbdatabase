class GameDay < ActiveRecord::Base
  belongs_to :season
  has_many   :games,        dependent: :destroy
  has_many   :transactions, dependent: :destroy

  def self.search(date)
    game_day = GameDay.find_by_date(date)
    unless game_day
      game_day = GameDay.create(season: Season.find_by_year(date.year), date: date, year: date.year, month: date.month, day: date.day)
      game_day.update(index: game_day.find_index)
    end
    game_day
  end

  def self.yesterday
    GameDay.search(DateTime.now.yesterday.to_date)
  end

  def self.today
    GameDay.search(DateTime.now.to_date)
  end

  def self.tomorrow
    GameDay.search(DateTime.now.tomorrow.to_date)
  end

  def create_matchups
    # if today? || tomorrow?
      Create::Matchups.new.create(self)
      Create::Bullpen.new.create(self)
    # end
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

  def update_local_hour
    Update::LocalHour.new.update(self)
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
    prev_date = date.prev_day(num_days)
  	GameDay.find_by_date(prev_date)
  end

  def date_string
    "#{date.year}/#{date.month}/#{date.day}"
  end

  def is_preseason?
    if month < 4 || (month == 4 && day < 3)
      true
    end
  end

  def today?
    self == GameDay.today ? true : false
  end

  def tomorrow?
    self == GameDay.tomorrow ? true : false
  end

end
