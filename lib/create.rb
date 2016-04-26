module Create

  def self.teams
    (0...@@name.size).each{|i|
	  team = Team.create(:name => @@name[i], :abbr => @@abbr[i], :game_abbr => @@game_abbr[i], :stadium => @@stadium[i], :zipcode => @@zipcode[i], :fangraph_id => @@fangraph_id[i], :league => @@league[i])
	  if @@east.include?(team.name)
	    team.update_attributes(timezone: -3)
	  elsif team.name == "Rockies"
	    team.update_attributes(timezone: -2)
	  elsif @@west.include?(team.name)
		team.update_attributes(timezone: -1)
	  else
	    team.update_attributes(timezone: 0)
	  end
	}
  end

  def self.new_teams
  	(0...@@team_attributes.size).each { |i|
  	  team_params = @@team_attributes[i]
  	  unless team = Team.find_by_name(team_params[:name])
  	  	team = Team.create(name: team_params[:name])
  	  end
  	  team.update()

  	}
  end

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


  @@zipcode = ["92806", "77002", "94621", "M5V 1J1", "30315", "53214", "63102", "60613", "85004", "90012", "94107",
			   "44115", "98134", "33125", "11368", "20003", "21201", "92101", "19148", "15212", "76011", "33705", "02215",
			   "45202", "80205", "64129", "48201", "55403", "60616", "10451"]

  @@league = ["AL", "AL", "AL", "AL", "NL", "NL", "NL", "NL", "NL", "NL", "NL", "AL", "AL", "NL", "NL", "NL", "AL", "NL",
		"NL", "NL", "AL", "AL", "AL", "NL", "NL", "AL", "AL", "AL", "AL", "AL"]

  @@fangraph_id = [1, 21, 10, 14, 16, 23, 28, 17, 15, 22, 30, 5, 11, 20, 25, 24, 2, 29, 26, 27, 13, 12, 3, 18, 19, 7, 6, 8, 4, 9]

  @@team_attributes = [
	{ name: "Angels",       abbr: "LAA", alt_abbr: "ANA", fangraph_id: 1,  city: "Anaheim",       stadium: "Angels Stadium", 			  league: "AL", division: "West",    zipcode: "92806",   timezone: -3},
	{ name: "Astros",       abbr: "HOU", alt_abbr: "HOU", fangraph_id: 21, city: "Houston",       stadium: "Minute Maid Park", 		      league: "AL", division: "West",    zipcode: "77002",   timezone: -1},
	{ name: "Athletics",    abbr: "OAK", alt_abbr: "OAK", fangraph_id: 10, city: "Oakland",       stadium: "Oakland Coliseum", 		      league: "AL", division: "West",    zipcode: "94621",   timezone: -3},
	{ name: "Blue Jays",    abbr: "TOR", alt_abbr: "TOR", fangraph_id: 14, city: "Toronto",       stadium: "Rogers Centre", 			  league: "AL", division: "East",    zipcode: "M5V 1J1", timezone: 0 },
	{ name: "Braves",       abbr: "ATL", alt_abbr: "ATL", fangraph_id: 16, city: "Atlanta",       stadium: "Turner Field", 				  league: "NL", division: "East",    zipcode: "30315",   timezone: -1},
	{ name: "Brewers",      abbr: "MIL", alt_abbr: "MIL", fangraph_id: 23, city: "Milwaukee",     stadium: "Miller Park", 				  league: "NL", division: "Central", zipcode: "53214",   timezone: -1},
	{ name: "Cardinals",    abbr: "STL", alt_abbr: "SLN", fangraph_id: 28, city: "St Louis",      stadium: "Busch Stadium", 			  league: "NL", division: "Central", zipcode: "63102",   timezone: -1},
	{ name: "Cubs",         abbr: "CHC", alt_abbr: "CHN", fangraph_id: 17, city: "Chicago",       stadium: "Wrigley Field", 			  league: "NL", division: "Central", zipcode: "60613",   timezone: -1},
	{ name: "Diamondbacks", abbr: "ARI", alt_abbr: "ARI", fangraph_id: 15, city: "Arizona",       stadium: "Chase Field", 				  league: "NL", division: "West",    zipcode: "85004",   timezone: -3},
	{ name: "Dodgers",      abbr: "LAD", alt_abbr: "LAN", fangraph_id: 22, city: "Los Angeles",   stadium: "Dodgers Stadium", 		      league: "NL", division: "West",    zipcode: "90012",   timezone: -3},
	{ name: "Giants",       abbr: "SFG", alt_abbr: "SFN", fangraph_id: 30, city: "San Francisco", stadium: "AT&T Park", 				  league: "NL", division: "West",    zipcode: "94107",   timezone: -3},
	{ name: "Indians",      abbr: "CLE", alt_abbr: "CLE", fangraph_id: 5,  city: "Cleveland",     stadium: "Progressive Field", 	      league: "AL", division: "Central", zipcode: "44115",   timezone: 0 },
	{ name: "Mariners",     abbr: "SEA", alt_abbr: "SEA", fangraph_id: 11, city: "Seattle",       stadium: "Safeco Park", 				  league: "AL", division: "West",    zipcode: "98134",   timezone: -3},
	{ name: "Marlins",      abbr: "MIA", alt_abbr: "MIA", fangraph_id: 20, city: "Miami", 		  stadium: "Marlins Park", 				  league: "NL", division: "East",    zipcode: "33125",   timezone: 0 },
	{ name: "Mets",         abbr: "NYM", alt_abbr: "NYN", fangraph_id: 25, city: "New York",      stadium: "Citi Field", 				  league: "NL", division: "East",    zipcode: "11368",   timezone: 0 },
	{ name: "Nationals",    abbr: "WSN", alt_abbr: "WAS", fangraph_id: 24, city: "Washington", 	  stadium: "Nationals Park", 			  league: "NL", division: "East",    zipcode: "20003",   timezone: 0 },
	{ name: "Orioles",      abbr: "BAL", alt_abbr: "BAL", fangraph_id: 2,  city: "Baltimore", 	  stadium: "Camden Yards", 				  league: "AL", division: "East",    zipcode: "21201",   timezone: 0 },
	{ name: "Padres",       abbr: "SDP", alt_abbr: "SDN", fangraph_id: 29, city: "San Diego", 	  stadium: "Petco Park", 				  league: "NL", division: "West",    zipcode: "92101",   timezone: -3},
	{ name: "Phillies",     abbr: "PHI", alt_abbr: "PHI", fangraph_id: 26, city: "Philadelphia",  stadium: "Citizens Bank Park",	      league: "NL", division: "East",    zipcode: "19148",   timezone: 0 },
	{ name: "Pirates",      abbr: "PIT", alt_abbr: "PIT", fangraph_id: 27, city: "Pittsburgh",    stadium: "PNC Park", 					  league: "NL", division: "West",    zipcode: "15212",   timezone: 0 },
	{ name: "Rangers",      abbr: "TEX", alt_abbr: "TEX", fangraph_id: 13, city: "Texas", 		  stadium: "Rangers Ballpark", 		      league: "AL", division: "East",    zipcode: "76011",   timezone: -1},
	{ name: "Rays",         abbr: "TBR", alt_abbr: "TBA", fangraph_id: 12, city: "Tampa Bay", 	  stadium: "Tropicana Field",   	      league: "AL", division: "East",    zipcode: "33705",   timezone: 0 },
	{ name: "Red Sox",      abbr: "BOS", alt_abbr: "BOS", fangraph_id: 3,  city: "Boston", 		  stadium: "Fenway Park",       	      league: "AL", division: "Central", zipcode: "02215",   timezone: 0 },
	{ name: "Reds",         abbr: "CIN", alt_abbr: "CIN", fangraph_id: 18, city: "Cincinnati", 	  stadium: "Great American Ball Park",    league: "NL", division: "West",    zipcode: "45202",   timezone: 0 },
	{ name: "Rockies",      abbr: "COL", alt_abbr: "COL", fangraph_id: 19, city: "Colorado", 	  stadium: "Coors Field", 				  league: "NL", division: "Central", zipcode: "80205",   timezone: -2},
	{ name: "Royals",       abbr: "KCR", alt_abbr: "KCA", fangraph_id: 7,  city: "Kansas City",   stadium: "Kauffman Stadium", 			  league: "AL", division: "Central", zipcode: "64129",   timezone: -1},
	{ name: "Tigers",       abbr: "DET", alt_abbr: "DET", fangraph_id: 6,  city: "Detroit",		  stadium: "Comerica Park", 			  league: "AL", division: "Central", zipcode: "48201",   timezone: 0 },
	{ name: "Twins",        abbr: "MIN", alt_abbr: "MIN", fangraph_id: 8,  city: "Minnesota", 	  stadium: "Target Field", 				  league: "AL", division: "Central", zipcode: "55403",   timezone: -1},
	{ name: "White Sox",    abbr: "CHW", alt_abbr: "CHA", fangraph_id: 4,  city: "Chicago", 	  stadium: "U.S. Cellular Field", 		  league: "AL", division: "Central", zipcode: "60616",   timezone: -1},
	{ name: "Yankees",      abbr: "NYY", alt_abbr: "NYA", fangraph_id: 9,  city: "New York",	  stadium: "Yankee Stadium", 			  league: "AL", division: "East",    zipcode: "10451",   timezone: 0 }
  ]


		
end