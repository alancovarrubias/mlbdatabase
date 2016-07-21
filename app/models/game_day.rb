class GameDay < ActiveRecord::Base
  belongs_to :season
  has_many   :games,        dependent: :destroy

  def self.search(date)
    return GameDay.find_or_create_by(season: Season.find_by_year(date.year), date: date)
  end

  def year
    date.year
  end

  def month
    date.month
  end

  def day
    date.day
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
    Create::Matchups.new.create(self)
    Create::Bullpen.new.create(self)
  end

  def create_bullpen
    Create::Bullpen.new.create(self)
  end

  def update_games
    Update::Games.new.update(self)
  end

  def delete_games
    games.destroy_all
  end

  def update_weather
    games.each { |game| game.update_weather }
  end

  def update_forecast
    if today? || tomorrow?
      games.each { |game| game.update_forecast }
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

  def previous_days(num_days)
    prev_date = date.prev_day(num_days)
  	GameDay.find_by_date(prev_date)
  end

  def date_string
    "#{year}/#{month}/#{day}"
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
