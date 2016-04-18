class Team < ActiveRecord::Base
	has_many :players
	has_many :lancers
	has_many :batters
end
