class Team < ActiveRecord::Base
  has_and_belongs_to_many :seasons
	has_many :players
	has_many :lancers
	has_many :batters

  def self.create_teams
    Create::Teams.create
  end

	def css
	  (city + name).gsub(/\s+/, "")
	end
  
end
