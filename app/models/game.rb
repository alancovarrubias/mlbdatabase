class Game < ActiveRecord::Base
  
  belongs_to :away_team, :class_name => 'Team'
  belongs_to :home_team, :class_name => 'Team'
  belongs_to :game_day
  has_many :innings
  has_many :pitcher_box_scores
  has_many :hitter_box_scores
  has_many :weathers, dependent: :destroy
  has_many :lancers, dependent: :destroy
  has_many :batters, dependent: :destroy

  def new_url
    game_day = self.game_day
	  return self.home_team.game_abbr + game_day.year.to_s + "%02d" % game_day.month + "%02d" % game_day.day + self.num
  end

  def get_forecast(time)
    update_forecast(self, time)
    update_pressure_forecast(self)
  end

  def get_weather
    update_weather(self)
  end

end
