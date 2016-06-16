module Create
  class Teams

  	def self.create
  	  @@team_attributes.each do |team_params|
        Team.find_or_create_by(team_params)
  	  end
    end

    @@team_attributes = [
			{ name: "Angels",       abbr: "LAA", game_abbr: "ANA", fangraph_id: 1,  city: "Anaheim",       stadium: "Angels Stadium", 			     league: "AL", division: "West",    zipcode: "92806",   timezone: -3},
			{ name: "Astros",       abbr: "HOU", game_abbr: "HOU", fangraph_id: 21, city: "Houston",       stadium: "Minute Maid Park", 		     league: "AL", division: "West",    zipcode: "77002",   timezone: -1},
			{ name: "Athletics",    abbr: "OAK", game_abbr: "OAK", fangraph_id: 10, city: "Oakland",       stadium: "Oakland Coliseum", 		     league: "AL", division: "West",    zipcode: "94621",   timezone: -3},
			{ name: "Blue Jays",    abbr: "TOR", game_abbr: "TOR", fangraph_id: 14, city: "Toronto",       stadium: "Rogers Centre", 			       league: "AL", division: "East",    zipcode: "M5V 1J1", timezone: 0 },
			{ name: "Braves",       abbr: "ATL", game_abbr: "ATL", fangraph_id: 16, city: "Atlanta",       stadium: "Turner Field", 				     league: "NL", division: "East",    zipcode: "30315",   timezone: -1},
			{ name: "Brewers",      abbr: "MIL", game_abbr: "MIL", fangraph_id: 23, city: "Milwaukee",     stadium: "Miller Park", 				       league: "NL", division: "Central", zipcode: "53214",   timezone: -1},
			{ name: "Cardinals",    abbr: "STL", game_abbr: "SLN", fangraph_id: 28, city: "St Louis",      stadium: "Busch Stadium", 			       league: "NL", division: "Central", zipcode: "63102",   timezone: -1},
			{ name: "Cubs",         abbr: "CHC", game_abbr: "CHN", fangraph_id: 17, city: "Chicago",       stadium: "Wrigley Field", 			       league: "NL", division: "Central", zipcode: "60613",   timezone: -1},
			{ name: "Diamondbacks", abbr: "ARI", game_abbr: "ARI", fangraph_id: 15, city: "Arizona",       stadium: "Chase Field", 				       league: "NL", division: "West",    zipcode: "85004",   timezone: -3},
			{ name: "Dodgers",      abbr: "LAD", game_abbr: "LAN", fangraph_id: 22, city: "Los Angeles",   stadium: "Dodgers Stadium", 		       league: "NL", division: "West",    zipcode: "90012",   timezone: -3},
			{ name: "Giants",       abbr: "SFG", game_abbr: "SFN", fangraph_id: 30, city: "San Francisco", stadium: "AT&T Park", 				         league: "NL", division: "West",    zipcode: "94107",   timezone: -3},
			{ name: "Indians",      abbr: "CLE", game_abbr: "CLE", fangraph_id: 5,  city: "Cleveland",     stadium: "Progressive Field", 	       league: "AL", division: "Central", zipcode: "44115",   timezone: 0 },
			{ name: "Mariners",     abbr: "SEA", game_abbr: "SEA", fangraph_id: 11, city: "Seattle",       stadium: "Safeco Park", 				       league: "AL", division: "West",    zipcode: "98134",   timezone: -3},
			{ name: "Marlins",      abbr: "MIA", game_abbr: "MIA", fangraph_id: 20, city: "Miami", 		     stadium: "Marlins Park", 				     league: "NL", division: "East",    zipcode: "33125",   timezone: 0 },
			{ name: "Mets",         abbr: "NYM", game_abbr: "NYN", fangraph_id: 25, city: "New York",      stadium: "Citi Field", 				       league: "NL", division: "East",    zipcode: "11368",   timezone: 0 },
			{ name: "Nationals",    abbr: "WSN", game_abbr: "WAS", fangraph_id: 24, city: "Washington",    stadium: "Nationals Park", 			     league: "NL", division: "East",    zipcode: "20003",   timezone: 0 },
			{ name: "Orioles",      abbr: "BAL", game_abbr: "BAL", fangraph_id: 2,  city: "Baltimore", 	   stadium: "Camden Yards", 				     league: "AL", division: "East",    zipcode: "21201",   timezone: 0 },
			{ name: "Padres",       abbr: "SDP", game_abbr: "SDN", fangraph_id: 29, city: "San Diego", 	   stadium: "Petco Park", 				       league: "NL", division: "West",    zipcode: "92101",   timezone: -3},
			{ name: "Phillies",     abbr: "PHI", game_abbr: "PHI", fangraph_id: 26, city: "Philadelphia",  stadium: "Citizens Bank Park",	       league: "NL", division: "East",    zipcode: "19148",   timezone: 0 },
			{ name: "Pirates",      abbr: "PIT", game_abbr: "PIT", fangraph_id: 27, city: "Pittsburgh",    stadium: "PNC Park", 					       league: "NL", division: "West",    zipcode: "15212",   timezone: 0 },
			{ name: "Rangers",      abbr: "TEX", game_abbr: "TEX", fangraph_id: 13, city: "Texas", 		     stadium: "Rangers Ballpark", 		     league: "AL", division: "East",    zipcode: "76011",   timezone: -1},
			{ name: "Rays",         abbr: "TBR", game_abbr: "TBA", fangraph_id: 12, city: "Tampa Bay", 	   stadium: "Tropicana Field",   	       league: "AL", division: "East",    zipcode: "33705",   timezone: 0 },
			{ name: "Red Sox",      abbr: "BOS", game_abbr: "BOS", fangraph_id: 3,  city: "Boston", 		   stadium: "Fenway Park",       	       league: "AL", division: "Central", zipcode: "02215",   timezone: 0 },
			{ name: "Reds",         abbr: "CIN", game_abbr: "CIN", fangraph_id: 18, city: "Cincinnati", 	 stadium: "Great American Ball Park",  league: "NL", division: "West",    zipcode: "45202",   timezone: 0 },
			{ name: "Rockies",      abbr: "COL", game_abbr: "COL", fangraph_id: 19, city: "Colorado", 	   stadium: "Coors Field", 				       league: "NL", division: "Central", zipcode: "80205",   timezone: -2},
			{ name: "Royals",       abbr: "KCR", game_abbr: "KCA", fangraph_id: 7,  city: "Kansas City",   stadium: "Kauffman Stadium", 			   league: "AL", division: "Central", zipcode: "64129",   timezone: -1},
			{ name: "Tigers",       abbr: "DET", game_abbr: "DET", fangraph_id: 6,  city: "Detroit",		   stadium: "Comerica Park", 			       league: "AL", division: "Central", zipcode: "48201",   timezone: 0 },
			{ name: "Twins",        abbr: "MIN", game_abbr: "MIN", fangraph_id: 8,  city: "Minnesota", 	   stadium: "Target Field", 				     league: "AL", division: "Central", zipcode: "55403",   timezone: -1},
			{ name: "White Sox",    abbr: "CHW", game_abbr: "CHA", fangraph_id: 4,  city: "Chicago", 	  	 stadium: "U.S. Cellular Field", 		   league: "AL", division: "Central", zipcode: "60616",   timezone: -1},
			{ name: "Yankees",      abbr: "NYY", game_abbr: "NYA", fangraph_id: 9,  city: "New York",	  	 stadium: "Yankee Stadium", 			     league: "AL", division: "East",    zipcode: "10451",   timezone: 0 },
      { name: "Marlins",      abbr: "FLA", game_abbr: "FLO", fangraph_id: 20, city: "Florida",       stadium: "Sun Life Stadium",          league: "NL", division: "East",    zipcode: "33056",   timezone: 0 },
      { name: "Devil Rays",   abbr: "TBD", game_abbr: "TBA", fangraph_id: 12, city: "Tampa Bay",     stadium: "Tropicana Field",           league: "AL", division: "East",    zipcode: "33705",   timezone: 0 },
      { name: "Expos",        abbr: "MON", game_abbr: "MON", fangraph_id: 24, city: "Montreal",      stadium: "Olympic Stadium",           league: "NL", division: "East",    zipcode: "H1V 3N7", timezone: 0 },
      { name: "Angels",       abbr: "ANA", game_abbr: "ANA", fangraph_id: 1,  city: "Anaheim",       stadium: "Angels Stadium",            league: "AL", division: "West",    zipcode: "92806",   timezone: -3}
    ]

  end	
end