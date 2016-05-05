class Game < ActiveRecord::Base

  include WeatherUpdate
  
  belongs_to :away_team, :class_name => 'Team'
  belongs_to :home_team, :class_name => 'Team'
  belongs_to :game_day
  has_many :weathers, dependent: :destroy
  has_many :lancers, dependent: :destroy
  has_many :batters, dependent: :destroy

  def url
    "#{home_team.game_abbr}#{game_day.year}%02d%02d#{num}" % [game_day.month, game_day.day]
  end

  def update_weather
    create_weathers(self)
    update_forecast(self)
    update_pressure_forecast(self)
    update_true_weather(self)
  end

  def away_pitcher
    lancers.find_by(starter: true, team_id: self.away_team_id)
  end

  def home_pitcher
    lancers.find_by(starter: true, team_id: self.home_team_id)
  end

  def true_weather
    weathers.find_by(hour: 1, station: "Actual")
  end

  def create_weathers
    if weathers.size == 0
      (1..3).each do |i|
        Weather.create(game: game, station: "Forecast", hour: i)
        Weather.create(game: game, station: "Actual", hour: i)
      end
    end
  end
  
end
