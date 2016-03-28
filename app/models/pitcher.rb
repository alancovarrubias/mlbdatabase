class Pitcher < ActiveRecord::Base
	belongs_to :team
	belongs_to :game

	def self.proto_pitchers
		Pitcher.where(:game_id => nil)
	end
end
