class Game < ActiveRecord::Base

  include WeatherUpdate
  
  belongs_to :away_team, :class_name => 'Team'
  belongs_to :home_team, :class_name => 'Team'
  belongs_to :game_day
  has_many :weathers, dependent: :destroy
  has_many :lancers, dependent: :destroy
  has_many :batters, dependent: :destroy

  def url
    game_day = self.game_day
	  return self.home_team.game_abbr + game_day.year.to_s + "%02d" % game_day.month + "%02d" % game_day.day + self.num
  end

  def update_weather
    game_day = self.game_day
    create_weathers(self)
    update_forecast(self)
    update_pressure_forecast(self)
    update_true_weather(self)
  end

end
