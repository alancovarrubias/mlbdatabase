namespace :testing do

	# def findDate(today)
	# 	year = today.year.to_s
	# 	month = today.month.to_s
	# 	day = today.day.to_s
	# 	hour = today.hour

	# 	if month.size == 1
	# 		month = '0' + month
	# 	end
	# 	if day.size == 1
	# 		day = '0' + day
	# 	end
	# 	return hour, day, month, year
	# end

	task :create => [:create_teams, :create_players] do
	end

	task :create_teams => :environment do
		require 'nokogiri'
		require 'open-uri'

		name = ["Angels", "Astros", "Athletics", "Blue Jays", "Braves", "Brewers", "Cardinals",
			"Cubs", "Diamondbacks", "Dodgers", "Giants", "Indians", "Mariners", "Marlins", "Mets",
			"Nationals", "Orioles", "Padres", "Phillies", "Pirates", "Rangers", "Rays", "Red Sox",
			"Reds", "Rockies", "Royals", "Tigers", "Twins", "White Sox", "Yankees"]

		stadium = ["Angels Stadium", "Minute Maid Park", "Oakland Coliseum", "Rogers Centre", "Turner Field",
			"Miller Park", "Busch Stadium", "Wrigley Field", "Chase Field", "Dodgers Stadium", "AT&T Park",
			"Progressive Field", "Safeco Park", "Marlins Park", "Citi Field", "Nationals Park", "Camden Yards",
			"Petco Park", "Citizens Bank Park", "PNC Park", "Rangers Ballpark", "Tropicana Field", "Fenway Park",
			"Great American Ball Park", "Coors Field", "Kauffman Stadium", "Comerica Park", "Target Field",
			"U.S. Cellular Field", "Yankee Stadium"]

		abbr = ["LAA", "HOU", "OAK", "TOR", "ATL", "MIL", "STL", "CHC", "ARI", "LAD", "SFG", "CLE", "SEA", "MIA", "NYM",
			"WSN", "BAL", "SDP", "PHI", "PIT", "TEX", "TBR", "BOS", "CIN", "COL", "KCR", "DET", "MIN", "CHW", "NYY"]

		game_abbr = ["ANA", "HOU", "OAK", "TOR", "ATL", "MIL", "SLN", "CHN", "ARI", "LAN", "SFN", "CLE", "SEA", "MIA", "NYN",
			"WAS", "BAL", "SDN", "PHI", "PIT", "TEX", "TBA", "BOS", "CIN", "COL", "KCA", "DET", "MIN", "CHA", "NYA"]

		zipcode = ["92806", "77002", "94621", "M5V 1J1", "30315", "53214", "63102", "60613", "85004", "90012", "94107",
			"44115", "98134", "33125", "11368", "20003", "21201", "92101", "19148", "15212", "76011", "33705", "02215", "45202",
			"80205", "64129", "48201", "55403", "60616", "10451"]

		league = ["AL", "AL", "AL", "AL", "NL", "NL", "NL", "NL", "NL", "NL", "NL", "AL", "AL", "NL", "NL", "NL", "AL", "NL",
			"NL", "NL", "AL", "AL", "AL", "NL", "NL", "AL", "AL", "AL", "AL", "AL"]

		fangraph_id = [1, 21, 10, 14, 16, 23, 28, 17, 15, 22, 30, 5, 11, 20, 25, 24, 2, 29, 26, 27, 13, 12, 3, 18, 19, 7, 6, 8, 4, 9]


		(0...name.size).each{|i|
			team = Team.create(:name => name[i], :abbr => abbr[i], :game_abbr => game_abbr[i], :stadium => stadium[i], :zipcode => zipcode[i], :fangraph_id => fangraph_id[i], :league => league[i])
			if team.name == "Angels" || team.name == "Athletics" || team.name == "Diamondbacks" || team.name == "Dodgers" || team.name == "Giants" || team.name == "Mariners" || team.name == "Padres"
				team.update_attributes(:timezone => -3)
			elsif team.name == "Rockies"
				team.update_attributes(:timezone => -2)
			elsif team.name == "Astros" || team.name == "Braves" || team.name == "Brewers" || team.name == "Cardinals" || team.name == "Cubs" || team.name == "Rangers" || team.name == "Royals" || team.name == "Twins" || team.name == "White Sox"
				team.update_attributes(:timezone => -1)
			else
				team.update_attributes(:timezone => 0)
			end
		}
		
	end
	
	task :create_players => :environment do
		Team.all.each do |team|
			team.create_players
		end
	end

	task :update_players => :environment do
		Team.all.each do |team|
			team.update_players
		end
	end

	task :test => :environment do
		require 'nokogiri'
		require 'open-uri'

		Game.where(:year => "2016", :month => "03", :day => "18").each do |game|
			game.update_weather
		end

		# url = "http://www.wunderground.com/history/airport/KFUL/2016/3/18/DailyHistory.html?req_city=Anaheim&req_state=CA&req_statename=California&reqdb.zip=92801&reqdb.magic=1&reqdb.wmo=99999"
		# doc = Nokogiri::HTML(open(url, "Accept-Encoding" => "plain"))
		# doc.css("#obsTable td").each_with_index do |stat, index|
		# 	case index%12
		# 	when 0
		# 		puts stat.text
		# 	end
		# end

	end























end