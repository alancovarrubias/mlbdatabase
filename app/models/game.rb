class Game < ActiveRecord::Base
  
  belongs_to :away_team, :class_name => 'Team'
  belongs_to :home_team, :class_name => 'Team'
  belongs_to :game_day
  has_many :weathers, dependent: :destroy
  has_many :lancers, dependent: :destroy
  has_many :batters, dependent: :destroy
  has_many :weather_sources, dependent: :destroy

  def url
    "#{home_team.game_abbr}%d%02d%02d#{num}" % [game_day.year, game_day.month, game_day.day]
  end

  def update_weather
    puts "#{id}"
    unless weathers.where(station: "Actual").size == 3
      puts "update #{id}"
      weathers.where(station: "Actual").destroy_all
      Update::Weathers.new.update(self)
    end
  end

  def update_forecast
    Update::Forecasts.new.update(self)
  end

  def update_weather_source
    Update::WeatherSources.new.update(self)
  end

  def update_hour_stadium_runs
    Update::OtherHour.new.update(self)
  end

  def away_pitcher
    lancers.find_by(starter: true, team: away_team)
  end

  def home_pitcher
    lancers.find_by(starter: true, team: home_team)
  end

  def true_weather
    weathers.find_by(hour: 1, station: "Actual")
  end
  
end
