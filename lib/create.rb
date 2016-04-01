module Create

	def self.teams
		(0...@@name.size).each{|i|
			team = Team.create(:name => @@name[i], :abbr => @@abbr[i], :game_abbr => @@game_abbr[i], :stadium => @@stadium[i], :zipcode => @@zipcode[i], :fangraph_id => @@fangraph_id[i], :league => @@league[i])
			if @@east.include?(team.name)
				team.update_attributes(:timezone => -3)
			elsif team.name == "Rockies"
				team.update_attributes(:timezone => -2)
			elsif @@west.include?(team.name)
				team.update_attributes(:timezone => -1)
			else
				team.update_attributes(:timezone => 0)
			end
		}
	end

	@@east = ["Angels", "Athletics", "Diamondbacks", "Dodgers", "Giants", "Mariners", "Padres"]

	@@west = ["Astros", "Braves", "Brewers", "Cardinals", "Cubs", "Rangers", "Royals", "Twins", "White Sox"]

	@@name = ["Angels", "Astros", "Athletics", "Blue Jays", "Braves", "Brewers", "Cardinals",
		"Cubs", "Diamondbacks", "Dodgers", "Giants", "Indians", "Mariners", "Marlins", "Mets",
		"Nationals", "Orioles", "Padres", "Phillies", "Pirates", "Rangers", "Rays", "Red Sox",
		"Reds", "Rockies", "Royals", "Tigers", "Twins", "White Sox", "Yankees"]

	@@stadium = ["Angels Stadium", "Minute Maid Park", "Oakland Coliseum", "Rogers Centre", "Turner Field",
		"Miller Park", "Busch Stadium", "Wrigley Field", "Chase Field", "Dodgers Stadium", "AT&T Park",
		"Progressive Field", "Safeco Park", "Marlins Park", "Citi Field", "Nationals Park", "Camden Yards",
		"Petco Park", "Citizens Bank Park", "PNC Park", "Rangers Ballpark", "Tropicana Field", "Fenway Park",
		"Great American Ball Park", "Coors Field", "Kauffman Stadium", "Comerica Park", "Target Field",
		"U.S. Cellular Field", "Yankee Stadium"]

	@@abbr = ["LAA", "HOU", "OAK", "TOR", "ATL", "MIL", "STL", "CHC", "ARI", "LAD", "SFG", "CLE", "SEA", "MIA", "NYM",
		"WSN", "BAL", "SDP", "PHI", "PIT", "TEX", "TBR", "BOS", "CIN", "COL", "KCR", "DET", "MIN", "CHW", "NYY"]

	@@game_abbr = ["ANA", "HOU", "OAK", "TOR", "ATL", "MIL", "SLN", "CHN", "ARI", "LAN", "SFN", "CLE", "SEA", "MIA", "NYN",
		"WAS", "BAL", "SDN", "PHI", "PIT", "TEX", "TBA", "BOS", "CIN", "COL", "KCA", "DET", "MIN", "CHA", "NYA"]

	@@zipcode = []

	@@league = ["AL", "AL", "AL", "AL", "NL", "NL", "NL", "NL", "NL", "NL", "NL", "AL", "AL", "NL", "NL", "NL", "AL", "NL",
		"NL", "NL", "AL", "AL", "AL", "NL", "NL", "AL", "AL", "AL", "AL", "AL"]

	@@fangraph_id = [1, 21, 10, 14, 16, 23, 28, 17, 15, 22, 30, 5, 11, 20, 25, 24, 2, 29, 26, 27, 13, 12, 3, 18, 19, 7, 6, 8, 4, 9]


		
end