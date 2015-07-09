class Game < ActiveRecord::Base
	belongs_to :away_team, :class_name => 'Team'
	belongs_to :home_team, :class_name => 'Team'
	has_many :pitchers
	has_many :hitters
	has_many :innings
	has_many :pitcher_box_scores
	has_many :hitter_box_scores
	def url
		return self.home_team.game_abbr + self.year + self.month + self.day + self.num
	end
end
