class Team < ActiveRecord::Base
	has_many :players
	has_many :lancers
	has_many :batters

	def css
	  (self.city + self.name).gsub(/\s+/, "")
	end
end
