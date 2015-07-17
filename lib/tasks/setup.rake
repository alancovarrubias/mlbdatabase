namespace :setup do

	# double headers may cause issues. Especially non-scheduled double headers which are most common
	desc "setup database"

	task :create => :environment do
		require 'nokogiri'
		require 'open-uri'

		def getHref(stat)
			href = stat.child.child['href']
			if href == nil
				href = stat.child['href']
			end
			return href[11..href.index(".")-1]
		end

		def getName(text)
			if text.include?("(")
				char = text.index("(")
				if text[char-2].match(/^[[:alpha:]]$/)
					name = text[0..char-2]
				else
					name = text[0..char-3]
				end
			elsif text.include?("*") || text.include?("#")
				name = text[0..-2]
			else
				name = text
			end
			return name
		end

		def create_teams
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

		def create_players
			teams = Team.all
			teams.each do |team|
				url = "http://www.baseball-reference.com/teams/#{team.abbr}/2015-roster.shtml"
				puts url
				doc = Nokogiri::HTML(open(url))
				pitcher = hitter = href = name = bathand = throwhand = nil
				pitcher_bool = false
			 	doc.css("#appearances td").each_with_index do |stat, index|
			 		text = stat.text
			 		case index%29
			 		when 0
			 			name = text
			 			href = getHref(stat)
			 			puts name
			 			puts href
			 		when 3
			 			bathand = text
			 		when 4
			 			throwhand = text
			 		when 13
			 			if text.to_i > 0
			 				pitcher_bool = true
			 			end
			 			if !hitter = Hitter.find_by_alias(href)
							Hitter.create(:name => name, :alias => href, :team_id => team.id, :game_id => nil,
								:bathand => bathand, :throwhand => throwhand)
						end
						if pitcher_bool
							if !pitcher = Pitcher.find_by_alias(href)
								Pitcher.create(:name => name, :alias => href, :team_id => team.id, :game_id => nil,
									:bathand => bathand, :throwhand => throwhand)
							end
						end
						pitcher_bool = false
			 		end		
			 	end

			 	hitter = pitcher = bathand = throwhand = name = nil
			 	pitcher_bool = false
			 	doc.css("#40man td").each_with_index do |stat, index|
			 		text = stat.text
			 		case index%14
			 		when 2
			 			name = text
			 		when 4
			 			if text == "Pitcher"
			 				pitcher_bool = true
			 			end
			 		when 8
			 			bathand = text
			 		when 9
			 			throwhand = text
			 		when 13
			 			if !hitter = Hitter.find_by_name(name)
			 				Hitter.create(:name => name, :alias => nil, :team_id => team.id, :game_id => nil,
									:bathand => bathand, :throwhand => throwhand)
			 			end
			 			if pitcher_bool
			 				if !pitcher = Pitcher.find_by_name(name)
			 					Pitcher.create(:name => name, :alias => nil, :team_id => team.id, :game_id => nil,
									:bathand => bathand, :throwhand => throwhand)
			 				end
			 			end
			 		end
			 	end
			end
		end

		create_teams
		create_players	
		
	end

	task :create_players => :environment do
		require 'nokogiri'
		require 'open-uri'

		def getHref(stat)
			href = stat.child.child['href']
			if href == nil
				href = stat.child['href']
			end
			return href[11..href.index(".")-1]
		end

		def getName(text)
			if text.include?("(")
				char = text.index("(")
				if text[char-2].match(/^[[:alpha:]]$/)
					name = text[0..char-2]
				else
					name = text[0..char-3]
				end
			elsif text.include?("*") || text.include?("#")
				name = text[0..-2]
			else
				name = text
			end
			return name
		end

		def create_players
			teams = Team.all
			teams.each do |team|
				url = "http://www.baseball-reference.com/teams/#{team.abbr}/2015-roster.shtml"
				puts url
				doc = Nokogiri::HTML(open(url))
				pitcher = hitter = href = name = bathand = throwhand = nil
				pitcher_bool = false
			 	doc.css("#appearances td").each_with_index do |stat, index|
			 		text = stat.text
			 		case index%29
			 		when 0
			 			name = text
			 			href = getHref(stat)
			 		when 3
			 			bathand = text
			 		when 4
			 			throwhand = text
			 		when 13
			 			if text.to_i > 0
			 				pitcher_bool = true
			 			end
			 			if !hitter = Hitter.find_by_alias(href)
							Hitter.create(:name => name, :alias => href, :team_id => team.id, :game_id => nil,
								:bathand => bathand, :throwhand => throwhand)
						end
						if pitcher_bool
							if !pitcher = Pitcher.find_by_alias(href)
								Pitcher.create(:name => name, :alias => href, :team_id => team.id, :game_id => nil,
									:bathand => bathand, :throwhand => throwhand)
							end
						end
						pitcher_bool = false
			 		end		
			 	end

			 	hitter = pitcher = bathand = throwhand = name = nil
			 	pitcher_bool = false
			 	doc.css("#40man td").each_with_index do |stat, index|
			 		text = stat.text
			 		case index%14
			 		when 2
			 			name = text
			 		when 4
			 			if text == "Pitcher"
			 				pitcher_bool = true
			 			end
			 		when 8
			 			bathand = text
			 		when 9
			 			throwhand = text
			 		when 13
			 			if !hitter = Hitter.find_by_name(name)
			 				Hitter.create(:name => name, :alias => nil, :team_id => team.id, :game_id => nil,
									:bathand => bathand, :throwhand => throwhand)
			 			end
			 			if pitcher_bool
			 				if !pitcher = Pitcher.find_by_name(name)
			 					Pitcher.create(:name => name, :alias => nil, :team_id => team.id, :game_id => nil,
									:bathand => bathand, :throwhand => throwhand)
			 				end
			 			end
			 		end
			 	end
			end
		end

		create_players	
		
	end

	task :fangraphs => :environment do
		require 'nokogiri'
		require 'open-uri'

		def nicknames(text)
			case text
			when 'Phil Gosselin'
				return 'Philip Gosselin'
			when 'Thomas Pham'
				return 'Tommy Pham'
			when 'Zachary Heathcott'
				return 'Slade Heathcott'
			when 'Daniel Burawa'
				return 'Danny Burawa'
			when 'Kenneth Roberts'
				return 'Kenny Roberts'
			when 'Dennis Tepera' 
				return 'Ryan Tepera'
			when 'John Leathersich'
				return 'Jack Leathersich'
			when 'Hyun-Jin Ryu'
				return 'Hyun-jin Ryu'
			when 'Tom Layne'
				return 'Tommy Layne'
			when 'Nathan Karns'
				return 'Nate Karns'
			when 'Matt Joyce'
				return 'Matthew Joyce'
			when 'Michael Morse'
				return 'Mike Morse'
			when 'Jackie Bradley Jr.'
				return 'Jackie Bradley'
			when 'Jackie Bradley Jr'
				return 'Jackie Bradley'
			when 'Steven Souza Jr.'
				return 'Steven Souza'
			when 'Reynaldo Navarro'
				return 'Rey Navarro'
			when 'Jung-ho Kang'
				return 'Jung Ho Kang'
			when 'Edward Easley'
				return 'Ed Easley'
			when 'JR Murphy'
				return 'John Ryan Murphy'
			when 'Delino Deshields Jr.'
				return 'Delino DeShields'
			when 'Steve Tolleson'
				return 'Steven Tolleson'
			when 'Daniel Dorn'
				return 'Danny Dorn'
			when 'Nicholas Tropeano'
				return 'Nick Tropeano'
			when 'Michael Montgomery'
				return 'Mike Montgomery'
			when 'Matthew Tracy'
				return 'Matt Tracy'
			when 'Andrew Schugel'
				return 'A.J. Schugel'
			when 'Matthew Wisler'
				return 'Matt Wisler'
			when 'Sugar Marimon'
				return 'Sugar Ray Marimon'
			when 'Nate Adcock'
				return 'Nathan Adcock'
			when 'Samuel Deduno'
				return 'Sam Deduno'
			when 'Joshua Ravin'
				return 'Josh Ravin'
			when 'Michael Strong'
				return 'Mike Strong'
			when 'Samuel Tuivailala'
				return 'Sam Tuivailala'
			when 'Joseph Donofrio'
				return 'Joey Donofrio'
			when 'Mitchell Harris'
				return 'Mitch Harris'
			when 'Christopher Rearick'
				return 'Chris Rearick'
			when 'Jeremy Mcbryde'
				return 'Jeremy McBryde'
			when 'Jorge de la Rosa'
				return 'Jorge De La Rosa'
			when 'Rubby de la Rosa'
				return 'Rubby De La Rosa'
			when 'Hyun-Jin Ryu'
				return 'Hyun-jin Ryu'
			end
		end

		def getFangraph(stat)
			href = stat.child['href']
			if href != nil
				first = href.index('=')+1
				last = href.index('&')
				return href[first...last]
			end
		end

		def letter?(lookAhead)
			lookAhead =~ /[[:alpha:]]/
		end

		(1..30).each do |i|
			url = "http://www.fangraphs.com/depthcharts.aspx?position=ALL&teamid=#{i}"
			doc = Nokogiri::HTML(open(url))

			hitters = Hitter.where(:game_id => nil)
			doc.css(".depth_chart:nth-child(58) td").each_with_index do |stat, index|
				case index%10
				when 0
					name = stat.text
					while !letter?(name[-1])
						name = name[0...-1]
					end
					fangraph_id = getFangraph(stat)
					if hitter = hitters.find_by_name(name)
						hitter.update_attributes(:fangraph_id => fangraph_id)
					elsif hitter = hitters.find_by_name(nicknames(name))
						hitter.update_attributes(:fangraph_id => fangraph_id)
					else
						if name != 'Total'
							puts name + ' not found'
						end
					end
				end
			end

			pitchers = Pitcher.where(:game_id => nil)
			doc.css(".depth_chart:nth-child(76) td").each_with_index do |stat, index|
				case index%10
				when 0
					name = stat.text
					while !letter?(name[-1])
						name = name[0...-1]
					end
					fangraph_id = getFangraph(stat)
					if pitcher = pitchers.find_by_name(name)
						pitcher.update_attributes(:fangraph_id => fangraph_id)
					elsif pitcher = pitchers.find_by_name(nicknames(name))
						pitcher.update_attributes(:fangraph_id => fangraph_id)
					else
						if name != 'Total' && name != 'The Others'
							puts name + ' not found'
						end
					end

					if hitter = hitters.find_by_name(name)
						hitter.update_attributes(:fangraph_id => fangraph_id)
					elsif hitter = hitters.find_by_name(nicknames(name))
						hitter.update_attributes(:fangraph_id => fangraph_id)
					else
						if name != 'Total' && name != 'The Others'
							puts name + ' not found'
						end
					end

				end
			end
		end
	end

	task :update => :environment do
		require 'nokogiri'
		require 'open-uri'

		def getName(text)
			if text.include?("(")
				char = text.index("(")
				if text[char-2].match(/^[[:alpha:]]$/)
					name = text[0..char-2]
				else
					name = text[0..char-3]
				end
			elsif text.include?("*") || text.include?("#")
				name = text[0..-2]
			else
				name = text
			end
			return name
		end

		def getHref(stat)
			href = stat.child.child['href']
			if href == nil
				href = stat.child['href']
			end
			return href[11..href.index(".")-1]
		end

		def getFangraph(stat)
			href = stat.child['href']
			if href != nil
				first = href.index('=')+1
				last = href.index('&')
				return href[first...last]
			end
		end

		year = Time.now.year
		hitters = Hitter.where(:game_id => nil)
		pitchers = Pitcher.where(:game_id => nil)
		teams = Team.all

		teams.each do |team|

			url = "http://www.baseball-reference.com/teams/#{team.abbr}/2015.shtml"
			doc = Nokogiri::HTML(open(url))
			puts url

			doc.css("#team_batting tbody td").each_with_index do |stat, index|
				text = stat.text
				case index%28
				when 2
					name = getName(text)
					href = getHref(stat)
					if hitter = hitters.find_by_name(name)
						if hitter.alias == ""
							hitter.update_attributes(:alias => href)
						end
					else
						Hitter.create(:game_id => nil, :name => name, :alias => href)
						puts 'Hitter ' + name + ' created'
					end
				end

			end

			doc.css("#team_pitching tbody td").each_with_index do |stat, index|
				text = stat.text
				case index%34
				when 2
					name = getName(text)
					href = getHref(stat)
					if pitcher = pitchers.find_by_name(name)
						if pitcher.alias == nil
							pitcher.update_attributes(:alias => href)
						end
					else
						Pitcher.create(:game_id => nil, :name => name, :alias => href)
						puts 'Pitcher ' + name + ' created'
					end
				end
			end
		end


		teams.each do |team|
			urls = Array.new
			urls << "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,5,21,14,16,38,37,50,54,43&season=#{year}&month=13&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=1&age=0&filter=&players=0"
			urls << "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,5,21,14,16,38,37,50,54,43&season=#{year}&month=14&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=1&age=0&filter=&players=0"
			urls << "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,5,21,14,16,38,37,50,61,43&season=#{year}&month=2&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=1&age=0&filter=&players=0"
			urls << "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,5,21,14,16,38,37,50,54,43&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=#{team.fangraph_id}&rost=1&age=0&filter=&players=0"
			urls << "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,5,21,14,16,38,37,50,54,43&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=#{team.fangraph_id}&rost=1&age=0&filter=&players=0"


			ab = sb = bb = so = slg = obp = wOBA = wRC = ld = hitter = name = nil
			urls.each_with_index do |url, url_index|
				puts url
				doc = Nokogiri::HTML(open(url))
				doc.css(".grid_line_regular").each_with_index do |stat, index|
					text = stat.text
					case index%12
					when 1
						name = text
						fangraph_id = getFangraph(stat).to_i
						hitter = hitters.find_by_fangraph_id(fangraph_id)
						if hitter == nil
							hitter = hitters.find_by_name(name)
						end
					when 3
						ab = text.to_i
					when 4
						sb = text.to_i
					when 5
						bb = text.to_i
					when 6
						so = text.to_i
					when 7
						slg = (text.to_f*1000).to_i
					when 8
						obp = (text.to_f*1000).to_i
					when 9
						wOBA = (text.to_f*1000).to_i
					when 10
						wRC = text.to_i
					when 11
						ld = text[0...-2].to_f
						if hitter != nil
							case url_index
							when 0
								hitter.update_attributes(:team_id => team.id, :fangraph_id => fangraph_id, :AB_L => ab, :SB_L => sb, :BB_L => bb, :SO_L => so, :SLG_L => slg, :OBP_L => obp, :wOBA_L => wOBA, :LD_L => ld, :wRC_L => wRC)
							when 1
								hitter.update_attributes(:team_id => team.id, :fangraph_id => fangraph_id, :AB_R => ab, :SB_R => sb, :BB_R => bb, :SO_R => so, :SLG_R => slg, :OBP_R => obp, :wOBA_R => wOBA, :LD_R => ld, :wRC_R => wRC)
							when 2
								hitter.update_attributes(:team_id => team.id, :fangraph_id => fangraph_id, :AB_14 => ab, :SB_14 => sb, :BB_14 => bb, :SO_14 => so, :SLG_14 => slg, :OBP_14 => obp, :wOBA_14 => wOBA, :LD_14 => ld, :wRC_14 => wRC)
							when 3
								hitter.update_attributes(:team_id => team.id, :fangraph_id => fangraph_id, :AB_previous_L => ab, :SB_previous_L => sb, :BB_previous_L => bb, :SO_previous_L => so, :SLG_previous_L => slg, :OBP_previous_L => obp, :wOBA_previous_L => wOBA, :LD_previous_L => ld, :wRC_previous_L => wRC)
							when 4
								hitter.update_attributes(:team_id => team.id, :fangraph_id => fangraph_id, :AB_previous_R => ab, :SB_previous_R => sb, :BB_previous_R => bb, :SO_previous_R => so, :SLG_previous_R => slg, :OBP_previous_R => obp, :wOBA_previous_R => wOBA, :LD_previous_R => ld, :wRC_previous_R => wRC)
							end
						else
							puts name + ' not found'
						end
					end
				end
			end
		end

		teams.each do |team|

			urls = Array.new

			url = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=1&age=0&filter=&players=0"
			url_l = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=1&age=0&filter=&players=0"
			url_r = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=1&age=0&filter=&players=0"
			url_30 = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=1&age=0&filter=&players=0"
			url_previous = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=#{team.fangraph_id}&rost=1&age=0&filter=&players=0"
			url_previous_l = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=#{team.fangraph_id}&rost=1&age=0&filter=&players=0"
			url_previous_r = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=#{team.fangraph_id}&rost=1&age=0&filter=&players=0"

			fip = name = pitcher = nil
			urls << url
			urls << url_previous
			urls.each_with_index do |url, url_index|
				puts url
				doc = Nokogiri::HTML(open(url))
				doc.css(".grid_line_regular").each_with_index do |stat, index|
					text = stat.text
					case index%4
					when 1
						name = text
						fangraph_id = getFangraph(stat).to_i
						pitcher = pitchers.find_by_fangraph_id(fangraph_id)
						if pitcher == nil
							pitcher = pitchers.find_by_name(name)
						end
					when 3
						fip = text.to_i
						if pitcher != nil
							case url_index
							when 0
								pitcher.update_attributes(:team_id => team.id, :FIP => fip)
							when 1
								pitcher.update_attributes(:FIP_previous => fip)
							end
			 			else
			 				puts name + ' not found'
			 			end
					end
			 	end
			end

			urls.clear
			urls << url_l
			urls << url_r

			pitcher = ld = whip = ip = so = bb = era = fb = xfip = kbb = woba = name = nil
			urls.each_with_index do |url, url_index|
				doc = Nokogiri::HTML(open(url))
				puts url
				doc.css(".grid_line_regular").each_with_index do |stat, index|
					text = stat.text
					case index%13
					when 1
						name = text
						fangraph_id = getFangraph(stat).to_i
						pitcher = pitchers.find_by_fangraph_id(fangraph_id)
						if pitcher == nil
							pitcher = pitchers.find_by_name(name)
						end
					when 3
						ld = text[0...-2].to_f
					when 4
						whip = text.to_f
					when 5
						ip = text.to_f
					when 6
						so = text.to_i
					when 7
						bb = text.to_i
					when 8
						era = text.to_f
					when 9
						fb = text[0...-2].to_f
					when 10
						xfip = text.to_i
					when 11
						kbb = text.to_f
					when 12
						wOBA = (text.to_f*1000).to_i
						if pitcher != nil
							case url_index
							when 0
								pitcher.update_attributes(:team_id => team.id, :LD_L => ld, :WHIP_L => whip, :IP_L => ip, :SO_L => so, :BB_L => bb, :ERA_L => era, :FB_L => fb, :xFIP_L => xfip, :KBB_L => kbb, :wOBA_L => wOBA)
							when 1
								pitcher.update_attributes(:LD_R => ld, :WHIP_R => whip, :IP_R => ip, :SO_R => so, :BB_R => bb, :ERA_R => era, :FB_R => fb, :xFIP_R => xfip, :KBB_R => kbb, :wOBA_R => wOBA)
							end
						else
							puts name + ' not found'
						end
					end
				end
			end

			pitcher = ld = whip = ip = so = nil
			puts url_30
			doc = Nokogiri::HTML(open(url_30))
			name = ld = whip = ip = so = bb = nil
			doc.css(".grid_line_regular").each_with_index do |stat, index| #Search through all the information. Use an instance variable to determine which information I want.
				text = stat.text
				case index%8
				when 1
					name = text
					fangraph_id = getFangraph(stat).to_i
					pitcher = pitchers.find_by_fangraph_id(fangraph_id)
					if pitcher == nil
						pitcher = pitchers.find_by_name(name)
					end
				when 3
					ld = text[0...-2].to_f
				when 4
					whip = text.to_f
				when 5
					ip = text.to_f
				when 6
					so = text.to_i
				when 7
					bb = text.to_i
					if pitcher != nil
						pitcher.update_attributes(:LD_30 => ld, :WHIP_30 => whip, :IP_30 => ip, :SO_30 => so, :BB_30 => bb)
					else
						puts name + ' not found'
					end
				end
			end

			urls.clear
			urls << url_previous_l
			urls << url_previous_r

			pitcher = name = fb = xfip = kbb = wOBA = ld = whip = ip = so = bb = nil
			urls.each_with_index do |url, url_index|
				puts url
				doc = Nokogiri::HTML(open(url))
				doc.css(".grid_line_regular").each_with_index do |stat, index|
					text = stat.text
					case index%11
					when 1
						name = text
						fangraph_id = getFangraph(stat).to_i
						pitcher = pitchers.find_by_fangraph_id(fangraph_id)
						if pitcher == nil
							pitcher = pitchers.find_by_name(name)
						end
					when 3
						whip = text.to_f
					when 4
						ip = text.to_f
					when 5
						so = text.to_f
					when 6
						bb = text.to_f
					when 7
						fb = text[0...-2].to_f
					when 8
						xfip = text.to_f
					when 9
						kbb = text.to_f
					when 10
						wOBA = (text.to_f*1000).to_i
						if pitcher != nil
							case url_index
							when 0
								pitcher.update_attributes(:team_id => team.id, :FB_previous_L => fb, :xFIP_previous_L => xfip, :KBB_previous_L => kbb, :wOBA_previous_L => wOBA)
							when 1
								pitcher.update_attributes(:FB_previous_R => fb, :xFIP_previous_R => xfip, :KBB_previous_R => kbb, :wOBA_previous_R => wOBA)
							end
						else
							puts name + ' not found'
						end
					end
				end
			end
		end
		
	end

	task :weather => :environment do

		require 'nokogiri'
		require 'open-uri'

		def update_weather

			year = Time.now.year.to_s
			month = Time.now.month.to_s
			day = Time.now.day.to_s
			if month.size == 1
				month = "0" + month
			end
			if day.size == 1
				day = "0" + day
			end



			url_array = ["https://weather.yahoo.com/united-states/california/anaheim-2354447/", "https://weather.yahoo.com/united-states/texas/houston-2424766/", "https://weather.yahoo.com/united-states/california/oakland-2463583/",
					"https://weather.yahoo.com/canada/ontario/toronto-4118/", "https://weather.yahoo.com/united-states/georgia/atlanta-2357024/", "https://weather.yahoo.com/united-states/wisconsin/milwaukee-2451822/",
					"https://weather.yahoo.com/united-states/missouri/st.-louis-2486982/", "https://weather.yahoo.com/united-states/illinois/chicago-2379574/", "https://weather.yahoo.com/united-states/arizona/phoenix-2471390/",
					"https://weather.yahoo.com/united-states/california/los-angeles-2442047/", "https://weather.yahoo.com/united-states/california/san-francisco-2487956/", "https://weather.yahoo.com/united-states/ohio/cleveland-2381475/",
					"https://weather.yahoo.com/united-states/washington/seattle-2490383/", "https://weather.yahoo.com/united-states/florida/miami-2450022/", "https://weather.yahoo.com/united-states/new-york/new-york-2459115/",
					"https://weather.yahoo.com/united-states/district-of-columbia/washington-2514815/", "https://weather.yahoo.com/united-states/maryland/baltimore-2358820/", "https://weather.yahoo.com/united-states/california/san-diego-2487889/",
					"https://weather.yahoo.com/united-states/pennsylvania/philadelphia-2471217/", "https://weather.yahoo.com/united-states/pennsylvania/pittsburgh-2473224/", "https://weather.yahoo.com/united-states/texas/arlington-2355944/",
					"https://weather.yahoo.com/united-states/florida/st.-petersburg-2487180/", "https://weather.yahoo.com/united-states/massachusetts/boston-2367105/", "https://weather.yahoo.com/united-states/ohio/cincinnati-2380358/",
					"https://weather.yahoo.com/united-states/colorado/denver-2391279/", "https://weather.yahoo.com/united-states/kansas/kansas-city-2430632/", "https://weather.yahoo.com/united-states/michigan/detroit-2391585/",
					"https://weather.yahoo.com/united-states/minnesota/minneapolis-2452078/", "https://weather.yahoo.com/united-states/illinois/chicago-2379574/", "https://weather.yahoo.com/united-states/new-york/bronx-91801630/"]


			url_hourly = ["http://www.intellicast.com/Local/Hourly.aspx?location=USCA0027", "http://www.intellicast.com/Local/Hourly.aspx?location=USTX0617", "http://www.intellicast.com/Local/Hourly.aspx?location=USCA0791",
					"http://www.intellicast.com/Local/Hourly.aspx?location=CAXX0504", "http://www.intellicast.com/Local/Hourly.aspx?location=USGA0028","http://www.intellicast.com/Local/Hourly.aspx?location=USWI0455",
					"http://www.intellicast.com/Local/Hourly.aspx?location=USMO0787", "http://www.intellicast.com/Local/Hourly.aspx?location=USIL0225", "http://www.intellicast.com/Local/Hourly.aspx?location=USAZ0166",
					"http://www.intellicast.com/Local/Hourly.aspx?location=USCA0638", "http://www.intellicast.com/Local/Hourly.aspx?location=USCA0987", "http://www.intellicast.com/Local/Hourly.aspx?location=USOH0195",
					"http://www.intellicast.com/Local/Hourly.aspx?location=USWA0395", "http://www.intellicast.com/Local/Hourly.aspx?location=USFL0316", "http://www.intellicast.com/Local/Hourly.aspx?location=USNY0339",
					"http://www.intellicast.com/Local/Hourly.aspx?location=USDC0001", "http://www.intellicast.com/Local/Hourly.aspx?location=USMD0018", "http://www.intellicast.com/Local/Hourly.aspx?location=USCA0982",
					"http://www.intellicast.com/Local/Hourly.aspx?location=USPA1276", "http://www.intellicast.com/Local/Hourly.aspx?location=USPA1290", "http://www.intellicast.com/Local/Hourly.aspx?location=USTX0045",
					"http://www.intellicast.com/Local/Hourly.aspx?location=USFL0438", "http://www.intellicast.com/Local/Hourly.aspx?location=USMA0046", "http://www.intellicast.com/Local/Hourly.aspx?location=USOH0188",
					"http://www.intellicast.com/Local/Hourly.aspx?location=USCO0105", "http://www.intellicast.com/Local/Hourly.aspx?location=USMO0460", "http://www.intellicast.com/Local/Hourly.aspx?location=USMI0229",
					"http://www.intellicast.com/Local/Hourly.aspx?location=USMN0503", "http://www.intellicast.com/Local/Hourly.aspx?location=USIL0225", "http://www.intellicast.com/Local/Hourly.aspx?location=USNY0172"]

			Game.where(:year => year, :month => month, :day => day).each do |game|

				puts game.url

				array_index = game.home_team_id-1
				url = url_array[array_index]
				doc = Nokogiri::HTML(open(url))
				pressure = nil
				doc.css(".second").each_with_index do |weather, index|
					if index == 2
						pressure = weather.text[0..4] + ' in'
						break
					end
				end
				game.update_attributes(:pressure_1 => pressure, :pressure_2 => pressure, :pressure_3 => pressure)

				url = url_hourly[array_index]
				puts url
				doc = Nokogiri::HTML(open(url))
				found = false
				var = int = 0
				temperature = humidity = precipitation = wind = nil
				doc.css("#forecastHours td").each_with_index do |weather, index|
					text = weather.text
					if index%14 == 0
						time = game.time
						if time[1] == ':'
							time = time[0] + ' PM'
						else
							time = time[0..1] + ' PM'
						end
						if text.include? time
							found = true
						end
					end
					if found
						case index%14
						when 2
							temperature = text+"F"
						when 6
							humidity = text
						when 7
							precipitation = text
						when 11
							wind = text
						end
					end
					if found && index%14 == 13
						if int == 0
							game.update_attributes(:humidity_1 => humidity, :precipitation_1 => precipitation, :wind_1 => wind, :temperature_1 => temperature)
						elsif int == 1
							game.update_attributes(:humidity_2 => humidity, :precipitation_2 => precipitation, :wind_2 => wind, :temperature_2 => temperature)
						elsif int == 2
							game.update_attributes(:humidity_3 => humidity, :precipitation_3 => precipitation, :wind_3 => wind, :temperature_3 => temperature)
							break
						end
						int += 1
					end
				end
			end
		end

		update_weather

	end

	task :matchups => :environment do
		require 'nokogiri'
		require 'open-uri'

		def getFangraphID(text)

			index = text.index("player/")
			text = text[index+7..-1]
			index = text.index("/")
			return text[0...index]
		end

		def starters(pitchers, hitters)
			pitchers.where(:starter => true).each do |pitcher|
				pitcher.update_attributes(:starter => false)
			end
			hitters.where(:starter => true).each do |hitter|
				hitter.update_attributes(:starter => false)
			end
		end

		def convertTime(game, time)

			if !time.include?(":")
				return ""
			end

			colon = time.index(":")

			original_hour = time[0...colon].to_i
			suffix = time[colon..-4]
			hour = original_hour + game.home_team.timezone


			# Checks the borderline cases
			if original_hour == 12 && hour != 12 || hour < 0
				suffix[suffix.index("P")] = "A"
			end

			if hour < 1
				hour += 12
			end

			return hour.to_s + suffix

		end

		today = Time.now
		year = today.year.to_s
		month = today.month.to_s
		day = today.day.to_s
		hour = today.hour

		if month.size == 1
			month = '0' + month
		end
		if day.size == 1
			day = '0' + day
		end

		nil_pitchers = Pitcher.where(:game_id => nil)
		nil_hitters = Hitter.where(:game_id => nil)
		todays_games = Game.where(:year => year, :month => month, :day => day)

		url = "http://www.baseballpress.com/lineups/#{DateTime.now.to_date}"
		doc = Nokogiri::HTML(open(url))

		home = Array.new
		away = Array.new
		gametime = Array.new

		# Find the games occurring today
		doc.css(".game-time").each do |time|
			gametime << time.text
		end

		doc.css(".team-name").each_with_index do |stat, index|
			team = Team.find_by_name(stat.text)
			if index%2 == 0
				away << team
			else
				home << team
			end
		end

		# find team duplicates to find double headers
		teams = home + away
		duplicates = teams.select{ |e| teams.count(e) > 1 }.uniq

		(0...gametime.size).each{ |i|

			games = todays_games.where(:home_team_id => home[i].id, :away_team_id => away[i].id)

			# Check for double headers
			if games.size == 1 && duplicates.include?(home[i])
				game = Game.create(:year => year, :month => month, :day => day, :home_team_id => home[i].id, :away_team_id => away[i].id, :num => '2')
			elsif games.size == 0 && duplicates.include?(home[i])
				game = Game.create(:year => year, :month => month, :day => day, :home_team_id => home[i].id, :away_team_id => away[i].id, :num => '1')
			elsif games.size == 0
				game = Game.create(:year => year, :month => month, :day => day, :home_team_id => home[i].id, :away_team_id => away[i].id, :num => '0')
			end

			if game != nil
				time = convertTime(game, gametime[i])
				game.update_attributes(:time => time)
				puts 'Game ' + game.url + ' created'
			end

		}

		if hour > 6 && hour < 20

			starters(nil_pitchers, nil_hitters)
			
			# Set pitchers starters true
			doc.css(".team-name+ div").each do |player|

				name = player.text
				href = player.child['data-bref']
				fangraph_id = getFangraphID(player.child['data-razz'])

				if name == "TBD"
					next
				end

				name = name[0...-4]
				if href != "" && pitcher = nil_pitchers.find_by_alias(href)
					pitcher.update_attributes(:starter => true, :fangraph_id => fangraph_id)
				elsif fangraph_id != 0 && pitcher = nil_pitchers.find_by_fangraph_id(fangraph_id)
					pitcher.update_attributes(:starter => true, :alias => href)
				elsif pitcher = nil_pitchers.find_by_name(name)
					pitcher.update_attributes(:starter => true, :alias => href, :fangraph_id => fangraph_id)
					puts pitcher.name + ' found by name'
				else
					puts text + ' not found'
				end

			end

			# Set hitters starter true
			doc.css(".players div").each_with_index do |player, index|
				text = player.text
				lineup = text[0].to_i
				name = player.last_element_child.child.to_s
				href = player.last_element_child['data-bref']
				fangraph_id = getFangraphID(player.last_element_child['data-razz'])

				if href != "" && hitter = nil_hitters.find_by_alias(href)
					hitter.update_attributes(:starter => true, :lineup => lineup, :fangraph_id => fangraph_id)
				elsif fangraph_id != 0 && hitter = nil_hitters.find_by_fangraph_id(fangraph_id)
					hitter.update_attributes(:starter => true, :lineup => lineup, :alias => href)
				elsif hitter = nil_hitters.find_by_name(name)
					hitter.update_attributes(:starter => true, :alias => href, :lineup => lineup, :fangraph_id => fangraph_id)
					puts hitter.name + ' found by name'
				else
					puts name + ' not found'
				end
			end


			todays_games = Game.where(:year => year, :month => month, :day => day).order("id ASC")
			var = team_index = 0
			game_index = -1
			team = nil
			doc.css(".player-link , .team-name").each do |player|
				text = player.text
				puts text
				var += 1
				if store = Team.find_by_name(text)
					puts text
					if team_index%2 == 0
						game_index += 1
					end
					team = store
					team_index += 1
					var = 0
					next
				end

				game = todays_games[game_index]

				game_pitchers = Pitcher.where(:game_id => game.id)
				game_hitters = Hitter.where(:game_id => game.id)

				case var
				when 1
					name = player.text
					href = player['data-bref']
					if game_pitchers.find_by_alias(href) == nil
						puts name + ' not in game pitchers'
						pitcher = nil_pitchers.find_by_alias(href)
						if pitcher == nil
							pitcher = nil_pitchers.find_by_name(name)
						end
						if pitcher != nil
							Pitcher.create(:game_id => game.id, :team_id => pitcher.team.id, :name => pitcher.name, :alias => pitcher.alias, :fangraph_id => pitcher.fangraph_id, :bathand => pitcher.bathand,
									:throwhand => pitcher.throwhand, :starter => true, :FIP => pitcher.FIP, :LD_L => pitcher.LD_L, :WHIP_L => pitcher.WHIP_L, :IP_L => pitcher.IP_L,
									:SO_L => pitcher.SO_L, :BB_L => pitcher.BB_L, :ERA_L => pitcher.ERA_L, :wOBA_L => pitcher.wOBA_L, :FB_L => pitcher.FB_L, :xFIP_L => pitcher.xFIP_L,
									:KBB_L => pitcher.KBB_L, :LD_R => pitcher.LD_R, :WHIP_R => pitcher.WHIP_R, :IP_R => pitcher.IP_R,
									:SO_R => pitcher.SO_R, :BB_R => pitcher.BB_R, :ERA_R => pitcher.ERA_R, :wOBA_R => pitcher.wOBA_R, :FB_R => pitcher.FB_R, :xFIP_R => pitcher.xFIP_R,
									:KBB_R => pitcher.KBB_R, :LD_30 => pitcher.LD_30, :WHIP_30 => pitcher.WHIP_30, :IP_30 => pitcher.IP_30, :SO_30 => pitcher.SO_30, :BB_30 => pitcher.BB_30, 
									:FIP_previous => pitcher.FIP_previous, :FB_previous_L => pitcher.FB_previous_L, :xFIP_previous_L => pitcher.xFIP_previous_L, :KBB_previous_L => pitcher.KBB_previous_L,
									:wOBA_previous_L => pitcher.wOBA_previous_L, :FB_previous_R => pitcher.FB_previous_R, :xFIP_previous_R => pitcher.xFIP_previous_R, :KBB_previous_R => pitcher.KBB_previous_R,
									:wOBA_previous_R => pitcher.wOBA_previous_R)
						else
							puts name + ' not found'
						end
					end
				when 2..19
					name = player.child
					href = player['data-bref']
					if game_hitters.find_by_alias(href) == nil
						hitter = nil_hitters.find_by_alias(href)
						if hitter == nil
							if name.class != "String"
								name = name.text
							end
							hitter = nil_hitters.find_by_name(name)
						end
						if hitter != nil
							if hitter.team == nil
								puts hitter.name
							end
							Hitter.create(:game_id => game.id, :team_id => hitter.team.id, :name => hitter.name, :alias => hitter.alias, :fangraph_id => hitter.fangraph_id, :bathand => hitter.bathand,
									:throwhand => hitter.throwhand, :lineup => hitter.lineup, :starter => true, :SB_L => hitter.SB_L, :wOBA_L => hitter.wOBA_L,
									:OBP_L => hitter.OBP_L, :SLG_L => hitter.SLG_L, :AB_L => hitter.AB_L, :BB_L => hitter.BB_L, :SO_L => hitter.SO_L, :LD_L => hitter.LD_L,
									:wRC_L => hitter.wRC_L, :SB_R => hitter.SB_R, :wOBA_R => hitter.wOBA_R, :OBP_R => hitter.OBP_R, :SLG_R => hitter.SLG_R, :AB_R => hitter.AB_R,
									:BB_R => hitter.BB_R, :SO_R => hitter.SO_R, :LD_R => hitter.LD_R, :wRC_R => hitter.wRC_R, :SB_14 => hitter.SB_14, :wOBA_14 => hitter.wOBA_14,
									:OBP_14 => hitter.OBP_14, :SLG_14 => hitter.SLG_14, :AB_14 => hitter.AB_14, :BB_14 => hitter.BB_14, :SO_14 => hitter.SO_14, :LD_14 => hitter.LD_14,
									:wRC_14 => hitter.wRC_14, :SB_previous_L => hitter.SB_previous_L, :wOBA_previous_L => hitter.wOBA_previous_L, :OBP_previous_L => hitter.OBP_previous_L,
									:SLG_previous_L => hitter.SLG_previous_L, :AB_previous_L => hitter.AB_previous_L, :BB_previous_L => hitter.BB_previous_L, :SO_previous_L => hitter.SO_previous_L,
									:LD_previous_L => hitter.LD_previous_L, :wRC_previous_L => hitter.wRC_previous_L, :SB_previous_R => hitter.SB_previous_R, :wOBA_previous_R => hitter.wOBA_previous_R, 
									:OBP_previous_R => hitter.OBP_previous_R, :SLG_previous_R => hitter.SLG_previous_R, :AB_previous_R => hitter.AB_previous_R, :BB_previous_R => hitter.BB_previous_R,
									:SO_previous_R => hitter.SO_previous_R, :LD_previous_R => hitter.LD_previous_R, :wRC_previous_R => hitter.wRC_previous_R)
						else
							puts name+ ' not found'
						end
					end
				end

			end


			# Get the bullpen pitchers and delete extra players
			nil_bullpen_pitchers = nil_pitchers.where(:bullpen => true)
			nil_starting_pitchers = nil_pitchers.where(:starter => true)
			nil_starting_hitters = nil_hitters.where(:starter => true)
			todays_games.each do |game|

				game_hitters = Hitter.where(:game_id => game.id)
				game_pitchers = Pitcher.where(:game_id => game.id)

				bullpen_pitchers = nil_bullpen_pitchers.where(:team_id => game.home_team.id) + nil_bullpen_pitchers.where(:team_id => game.away_team.id)

				bullpen_pitchers.each do |pitcher|
					if game_pitchers.find_by_alias(pitcher.alias) == nil
						Pitcher.create(:game_id => game.id, :team_id => pitcher.team.id, :name => pitcher.name, :alias => pitcher.alias, :fangraph_id => pitcher.fangraph_id, :bathand => pitcher.bathand,
							:throwhand => pitcher.throwhand, :bullpen => true, :one => pitcher.one, :two => pitcher.two, :three => pitcher.three, :FIP => pitcher.FIP, :LD_L => pitcher.LD_L, :WHIP_L => pitcher.WHIP_L, :IP_L => pitcher.IP_L,
							:SO_L => pitcher.SO_L, :BB_L => pitcher.BB_L, :ERA_L => pitcher.ERA_L, :wOBA_L => pitcher.wOBA_L, :FB_L => pitcher.FB_L, :xFIP_L => pitcher.xFIP_L,
							:KBB_L => pitcher.KBB_L, :LD_R => pitcher.LD_R, :WHIP_R => pitcher.WHIP_R, :IP_R => pitcher.IP_R,
							:SO_R => pitcher.SO_R, :BB_R => pitcher.BB_R, :ERA_R => pitcher.ERA_R, :wOBA_R => pitcher.wOBA_R, :FB_R => pitcher.FB_R, :xFIP_R => pitcher.xFIP_R,
							:KBB_R => pitcher.KBB_R, :LD_30 => pitcher.LD_30, :WHIP_30 => pitcher.WHIP_30, :IP_30 => pitcher.IP_30, :SO_30 => pitcher.SO_30, :BB_30 => pitcher.BB_30, 
							:FIP_previous => pitcher.FIP_previous, :FB_previous_L => pitcher.FB_previous_L, :xFIP_previous_L => pitcher.xFIP_previous_L, :KBB_previous_L => pitcher.KBB_previous_L,
							:wOBA_previous_L => pitcher.wOBA_previous_L, :FB_previous_R => pitcher.FB_previous_R, :xFIP_previous_R => pitcher.xFIP_previous_R, :KBB_previous_R => pitcher.KBB_previous_R,
							:wOBA_previous_R => pitcher.wOBA_previous_R)
					end
				end


				starting_pitchers = game_pitchers.where(:starter => true)
				starting_hitters = game_hitters.where(:starter => true)
				starting_hitters.each do |hitter|
					if !nil_hitters.find_by_alias(hitter.alias).starter
						if !nil_hitters.find_by_name(hitter.name).starter
							hitter.destroy
							puts hitter.name + ' destroyed'
						end
					end
				end

				starting_pitchers.each do |pitcher|
					if !nil_pitchers.find_by_alias(pitcher.alias).starter
						if !nil_pitchers.find_by_name(pitcher.name).starter
							pitcher.destroy
							puts pitcher.name + ' destroyed'
						end
					end
				end
			end
		end

	end


	task :tomorrow => :environment do
		require 'nokogiri'
		require 'open-uri'

		def convertTime(game, time)

			if !time.include?(":")
				return ""
			end

			colon = time.index(":")

			original_hour = time[0...colon].to_i
			suffix = time[colon..-4]
			hour = original_hour + game.home_team.timezone


			# Checks the borderline cases
			if original_hour == 12 && hour != 12 || hour < 0
				suffix[suffix.index("P")] = "A"
			end

			if hour < 1
				hour += 12
			end

			return hour.to_s + suffix

		end


		def starters()
			Pitcher.all.where(:tomorrow_starter => true, :game_id => nil).each do |pitcher|
				pitcher.update_attributes(:tomorrow_starter => false)
			end
		end


		url = "http://www.baseballpress.com/lineups/#{DateTime.now.tomorrow.to_date}"
		doc = Nokogiri::HTML(open(url))

		home = Array.new
		away = Array.new
		gametime = Array.new

		doc.css(".game-time").each do |time|
			gametime << time.text
		end

		doc.css(".team-name").each_with_index do |stat, index|
			team = Team.find_by_name(stat.text)
			if index%2 == 0
				away << team
			else
				home << team
			end
		end

		year = Time.now.tomorrow.year.to_s
		month = Time.now.tomorrow.month.to_s
		day = Time.now.tomorrow.day.to_s

		if month.size == 1
			month = '0' + month
		end
		if day.size == 1
			day = '0' + day
		end

		count = 1
		todays_games = Game.where(:year => year, :month => month, :day => day)
		(0...gametime.size).each{|i|
			games = todays_games.where(:home_team_id => home[i].id, :away_team_id => away[i].id)
			# Double header issues are located here
			if games.size == 2
				if count == 1
					game = games.first
				else
					game = games.second
					count = 0
				end
				time = convertTime(game, gametime[i])
				game.update_attributes(:time => time)
				count += 1
			elsif games.size == 1
				game = games.first
				time = convertTime(game, gametime[i])
				game.update_attributes(:time => time)
			else
				game = Game.create(:year => year, :month => month, :day => day, :home_team_id => home[i].id, :away_team_id => away[i].id, :num => '0')
				time = convertTime(game, gametime[i])
				game.update_attributes(:time => time)
				puts "Game created " + game.url
			end
		}


		starters()

		url = "http://www.baseballpress.com/lineups/#{DateTime.now.tomorrow.to_date}"
		puts url
		doc = Nokogiri::HTML(open(url))
		
		pitchers = Pitcher.where(:game_id => nil)
		doc.css(".team-name+ div").each_with_index do |player, index|
			text = player.text
			href = player.child['data-bref']
			fangraph_id = player.child['data-mlb']
			if text == "TBD"
				next
			end
			name = text[0...-4]
			if pitcher = pitchers.find_by_fangraph_id(fangraph_id)
				pitcher.update_attributes(:tomorrow_starter => true)
			elsif pitcher = pitchers.find_by_alias(href)
				pitcher.update_attributes(:tomorrow_starter => true)
			elsif pitcher = pitchers.find_by_name(text)
				pitcher.update_attributes(:tomorrow_starter => true)
			else
				pitcher = Pitcher.create(:name => name, :tomorrow_starter => true, :alias => href, :fangraph_id => fangraph_id)
				if index%2 == 0
					pitcher.update_attributes(:team_id => away[index/2].id)
				else
					pitcher.update_attributes(:team_id => home[index/2].id)
				end
				puts pitcher.name + ' created'
			end
		end

	end

	task :bullpen => :environment do
		require 'nokogiri'
		require 'open-uri'

		def bullpen()
			Pitcher.where(:bullpen => true, :game_id => nil).each do |pitcher|
				pitcher.update_attributes(:bullpen => false)
			end
		end

		def getNum(text)
			if text == "N/G"
				return 0
			else
				return text.to_i
			end
		end

		bullpen()

		url = "http://www.baseballpress.com/bullpenusage"
		doc = Nokogiri::HTML(open(url))
		bool = false
		pitcher = nil
		pitchers = Pitcher.where(:game_id => nil)
		var = one = two = three = 0
		doc.css(".league td").each do |bullpen|
			text = bullpen.text
			case var
			when 1
				one = getNum(text)
				var += 1
			when 2
				two = getNum(text)
				var += 1
			when 3
				three = getNum(text)
				var = 0
				if pitcher != nil
					pitcher.update_attributes(:bullpen => true, :one => one, :two => two, :three => three)
				end
			end
			if text.include?("(")
				text = text[0...-4]
				href = bullpen.child['data-bref']
				fangraph_id = bullpen.child['data-mlb']
				if pitcher = pitchers.find_by_name(text)
				elsif pitcher = pitchers.find_by_fangraph_id(fangraph_id)
				elsif pitcher = pitchers.find_by_alias(href)
				else
					puts 'Bullpen pitcher ' + text + ' not found'
					pitcher = nil
				end
				var = 1
			end
		end	
	end


	task :ump => :environment do
		require 'nokogiri'
		require 'open-uri'

		url = "http://www.statfox.com/mlb/umpiremain.asp"
		doc = Nokogiri::HTML(open(url))

		year = Time.now.year.to_s
		month = Time.now.month.to_s
		day = Time.now.day.to_s
		if month.size == 1
			month = "0" + month
		end
		if day.size == 1
			day = "0" + day
		end
		id = var = 0
		team = nil
		doc.css(".datatable a").each do |data|
			var += 1
			if var%3 == 2
				id = data['href']
			elsif var%3 == 0
				if data.text.size == 3
					var = 1
					next
				end
				ump = data.text
				case id
				when /ANGELS/
					team = "Angels"
				when /HOUSTON/
					team = "Astros"
				when /OAKLAND/
					team = "Athletics"
				when /TORONTO/
					team = "Blue Jays"
				when /ATLANTA/
					team = "Braves"
				when /MILWAUKEE/
					team = "Brewers"
				when /LOUIS/
					team = "Cardinals"
				when /CUBS/
					team = "Cubs"
				when /ARIZONA/
					team = "Diamondbacks"
				when /DODGERS/
					team = "Dodgers"
				when /FRANCISCO/
					team = "Giants"
				when /CLEVELAND/
					team = "Indians"
				when /SEATTLE/
					team = "Mariners"
				when /MIAMI/
					team = "Marlins"
				when /METS/
					team = "Mets"
				when /WASHINGTON/
					team = "Nationals"
				when /BALTIMORE/
					team = "Orioles"
				when /DIEGO/
					team = "Padres"
				when /PHILADELPHIA/
					team = "Phillies"
				when /PITTSBURGH/
					team = "Pirates"
				when /TEXAS/
					team = "Rangers"
				when /TAMPA/
					team = "Rays"
				when /BOSTON/
					team = "Red Sox"
				when /CINCINATTI/
					team = "Reds"
				when /COLORADO/
					team = "Rockies"
				when /KANSAS/
					team = "Royals"
				when /DETROIT/
					team = "Tigers"
				when /MINNESOTA/
					team = "Twins"
				when /WHITE/
					team = "White Sox"
				when /YANKEES/
					team = "Yankees"
				else
					team = "Not found"
				end
				if team = Team.find_by_name(team)
					puts ump
					puts team.name
					Game.where(:year => year, :month => month, :day => day, :home_team_id => team.id).first.update_attributes(:ump => ump)
				end
			end
		end
	end

	task :boxscores => :environment do
		require 'nokogiri'
		require 'open-uri'

		def getHref(stat)
			href = stat.last_element_child['href']
			return href[11..href.index(".")-1]
		end

		def getfangraphID(stat)
			href = stat.child['href']
			index = href.index("=")
			href = href[index+1..-1]
			index = href.index("&")
			href = href[0...index]
			return href.to_i
		end

		yesterday = Time.now.yesterday
		year = yesterday.year.to_s
		month = yesterday.month.to_s
		day = yesterday.day.to_s

		if month.size == 1
			month = "0" + month
		end

		if day.size == 1
			day = "0" + day
		end

		games = Game.where(:year => year, :month => month, :day => day)
		nil_pitchers = Pitcher.where(:game_id => nil)
		nil_hitters = Hitter.where(:game_id => nil)

		games.each do |game|

			if game.pitcher_box_scores.size != 0
				next
			end

			url = "http://www.fangraphs.com/boxscore.aspx?date=#{game.year}-#{game.month}-#{game.day}&team=#{game.home_team.fangraph_abbr}&dh=#{game.num}&season=#{game.year}"
			doc = Nokogiri::HTML(open(url))
			puts url

			if doc == nil
				puts 'game did not work'
				next
			end

			array = ["#WinsBox1_dgab_ctl00 .grid_line_regular", "#WinsBox1_dghb_ctl00 .grid_line_regular", "#WinsBox1_dgap_ctl00 .grid_line_regular", "#WinsBox1_dghp_ctl00 .grid_line_regular"]

			array.each_with_index do |css, css_index|

				if css_index < 2
					int = 12
				else
					int = 11
				end

				if css_index%2 == 0
					home = false
				else
					home = true
				end

				name = hitter = pitcher = href = bo = pa = h = hr = r = rbi = bb = so = woba = pli = wpa = nil
				doc.css(css).each_with_index do |stat, index|
					text = stat.text
					case index%int
					when 0
						name = stat.child.text
						href = 0
						if name != 'Total'
							href = getfangraphID(stat)
							if css_index < 2
								if hitter = nil_hitters.find_by_fangraph_id(href)
								elsif hitter = nil_hitters.find_by_name(name)
									hitter.update_attributes(:fangraph_id => href)
								else
									puts 'hitter ' + name + ' not found, fix fangraph_id'
									puts href
								end
							else
								if pitcher = nil_pitchers.find_by_fangraph_id(href)
								elsif pitcher = nil_pitchers.find_by_name(name)
									pitcher.update_attributes(:fangraph_id => href)
								else
									puts 'pitcher ' + name + ' not found, fix fangraph_id'
									puts href
								end
							end
						end
					when 1
						if css_index < 2
							bo = text.to_i
						else
							bo = text.to_f
						end
					when 2
						pa = text.to_i
					when 3
						h = text.to_i
					when 4
						hr = text.to_i
					when 5
						r = text.to_i
					when 6
						rbi = text.to_i
					when 7
						bb = text.to_i
					when 8
						if css_index < 2
							so = text.to_i
						else
							so = text.to_f
						end
					when 9
						if css_index < 2
							woba = (text.to_f*1000).to_i
						else
							woba = text.to_f
						end
					when 10
						pli = text.to_f
						if css_index >= 2
							if pitcher != nil
								PitcherBoxScore.create(:game_id => game.id, :pitcher_id => pitcher.id, :name => pitcher.name, :home => home, :IP => bo, :TBF => pa, :H => h, :HR => hr, :ER => r, :BB => rbi,
									:SO => bb, :FIP => so, :pLI => woba, :WPA => pli)
							else
								PitcherBoxScore.create(:game_id => game.id, :pitcher_id => nil, :name => name, :home => home, :IP => bo, :TBF => pa, :H => h, :HR => hr, :ER => r, :BB => rbi,
									:SO => bb, :FIP => so, :pLI => woba, :WPA => pli)
							end
							pitcher = nil
						end
					when 11
						wpa = text.to_f
						if hitter != nil
							HitterBoxScore.create(:game_id => game.id, :hitter_id => hitter.id, :name => hitter.name, :home => home, :BO => bo, :PA => pa, :H => h, :HR => hr, :R => r, :RBI => rbi, :BB => bb,
									:SO => so, :wOBA => woba, :pLI => pli, :WPA => wpa)
						else
							HitterBoxScore.create(:game_id => game.id, :hitter_id => nil, :name => name, :home => home, :BO => bo, :PA => pa, :H => h, :HR => hr, :R => r, :RBI => rbi, :BB => bb,
									:SO => so, :wOBA => woba, :pLI => pli, :WPA => wpa)
						end
						hitter = nil
					end

				end

			end
		end
	end

	task :test => :environment do

		year = Time.now.year.to_s
		month = Time.now.month.to_s
		day = Time.now.day.to_s

		if month.size == 1
			month = "0" + month
		end

		if day.size == 1
			day = "0" + day
		end

		Game.where(:year => year, :month => month, :day => day).each do |game|
			pitchers_size = game.pitchers.where(:starter => true).size
			if pitchers_size != 2
				puts game.home_team.name + ' have ' + pitchers_size.to_s + ' pitchers'
			end
			hitters_size = game.hitters.where(:starter => true).size
			if hitters_size != 18
				puts game.home_team.name + ' have ' + hitters_size.to_s + ' hitters'
			end
		end

		year = Time.now.tomorrow.year.to_s
		month = Time.now.tomorrow.month.to_s
		day = Time.now.tomorrow.day.to_s

		if month.size == 1
			month = "0" + month
		end

		if day.size == 1
			day = "0" + day
		end

		Game.where(:year => year, :month => month, :day => day).each do |game|
			pitchers_size = (Pitcher.where(:tomorrow_starter => true, :team_id => game.home_team.id) + Pitcher.where(:tomorrow_starter => true, :team_id => game.away_team.id)).size
			if pitchers_size != 2
				puts game.home_team.name + ' have ' + pitchers_size.to_s + ' tomorrow pitchers'
			end
		end
	end

	task :see_multiples => :environment do

		nil_pitchers = Pitcher.where(:game_id => nil)
		href = Array.new
		nil_pitchers.each do |pitcher|
			if !href.include?(pitcher.name)
				href << pitcher.name
			else
				puts pitcher.name
			end
		end


	end

	task :iwantitnow => :environment do
		require 'open-uri'
		require 'mechanize'

		agent = Mechanize.new
		agent.add_auth("http://iwantitnow.parseapp.com/customers", "michele", "jeffers")
		agent.get("http://iwantitnow.parseapp.com/customers")
		var = 0
		agent.page.search("td").each_with_index do |stat, index|
			if index > 6
				var += 1
			end
			case var%8
			when 3
				puts stat.text
			end
		end


	end


end