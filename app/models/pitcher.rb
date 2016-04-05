class Pitcher < ActiveRecord::Base
	
  belongs_to :team
  belongs_to :game

  def self.proto_pitchers
    Pitcher.where(game_id: nil)
  end

  def self.bullpen_pitchers
  	Pitcher.proto_pitchers.where(bullpen: true)
  end 

  def self.starting_pitchers
  	Pitcher.proto_pitchers.where(starter: true)
  end

  def self.tomorrow_starting_pitchers
    Pitcher.proto_pitchers.where(tomorrow_starter: true)
  end

end
