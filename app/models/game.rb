require 'nokogiri'
require 'open-uri'
require 'timeout'

class Game < ActiveRecord::Base

  include UpdateWeather
  
  belongs_to :away_team, :class_name => 'Team'
  belongs_to :home_team, :class_name => 'Team'
  belongs_to :game_day
  has_many :pitchers
  has_many :hitters
  has_many :innings
  has_many :pitcher_box_scores
  has_many :hitter_box_scores
  has_many :weathers, dependent: destroy
  has_many :lancers, dependent: destroy
  has_many :batters, dependent: destroy
  
  def self.days_games(time)
    Game.where(:year => time.year.to_s, :month => "%02d" % time.month, :day => "%02d" % time.day)
  end

  def url
    game_day = self.game_day
    return self.home_team.game_abbr + self.year.to_s + "%02d" % self.month + "%02d" % self.day + self.num
  end

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
