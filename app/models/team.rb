class Team < ActiveRecord::Base
	has_many :pitchers
	has_many :hitters
end
