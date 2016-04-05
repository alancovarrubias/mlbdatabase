class Hitter < ActiveRecord::Base

  belongs_to :team
  belongs_to :game

  def self.proto_hitters
  	Hitter.where(game_id: nil)
  end

  def self.starting_hitters
  	Hitter.proto_hitters.where(starter: true)
  end

end
