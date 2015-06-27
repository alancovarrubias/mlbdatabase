namespace :setup do

	# double headers may cause issues. Especially non-scheduled double headers which are most common
	desc "setup database"

	task :create => :environment do
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
			zipcode = ["92806", "77002", "94621", "M5V 1J1", "30315", "53214", "63102", "60613", "85004", "90012", "94107",
				"44115", "98134", "33125", "11368", "20003", "21201", "92101", "19148", "15212", "76011", "33705", "02215", "45202",
				"80205", "64129", "48201", "55403", "60616", "10451"]

			(0...name.size).each{|i|
				team = Team.create(:name => name[i], :abbr => abbr[i], :stadium => stadium[i], :zipcode => zipcode[i])
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
				href = name = bathand = throwhand = nil
				pitcher = false
				doc.css("#40man td").each_with_index do |stat, index| #Search through all the information. Use an instance variable to determine which information I want.
					text = stat.text
					case index%14
					when 2
						name = getName(text)
					when 4
						if text == 'Pitcher'
							pitcher = true
						end
					when 8
						bathand = text
					when 9
						throwhand = text
					when 10
						if !Hitter.find_by_name(name)
							Hitter.create(:name => name, :team_id => team.id, :game_id => nil,
								:bathand => bathand, :throwhand => throwhand)
						end
						if pitcher
							if !Pitcher.find_by_name(name)
								Pitcher.create(:name => name, :team_id => team.id, :game_id => nil,
									:bathand => bathand, :throwhand => throwhand)
							end
						end
						pitcher = false
					end
			 	end
			end
		end

		create_teams
		create_players	
		
	end


	task :create_games => :environment do
		require 'nokogiri'
		require 'open-uri'


		month = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
		@hash = Hash.new
		month.each_with_index do |value, index|
			@hash[value] = index+1
		end

		def convertDate(date)
			comma = date.index(",")
			date = date[comma+2..-1]
			space = date.index(" ")
			month = date[0...space]
			day = date[space+1..-1]
			if day.include?('(')
				day = day[0...day.index('(')-1]
			end
			month = @hash[month].to_s
			if month.size == 1
				month = '0' + month
			end
			if day.size == 1
				day = '0' + day
			end
			return [month, day]
		end

		def setTeams(amp, away, home)
			if amp
				var = away
				away = home
				home = var
			end
			return [away, home]
		end

		year = '2015'
		teams_used = Array.new
		Team.all.each do |team|

			teams_used << team
			url = "http://www.baseball-reference.com/teams/#{team.abbr}/#{year}-schedule-scores.shtml"
			doc = Nokogiri::HTML(open(url))

			# initialize variables out of scope
			num = var = 0
			amp = seen = false
			month = day = away = home = nil
			doc.css("#team_schedule td").each_with_index do |stat, index|

				text = stat.text

				if var%21 == 3 && text == 'preview'
					break
				end

				case var%21
				when 2
					month, day = convertDate(text)
					if text.include?('(')
						num = text[-2]
					else
						num = '0'
					end
				when 4
					home = Team.find_by_abbr(text)
					if home == nil
						puts text
					end
				when 5
					if text == "@"
						amp = true
					else
						amp = false
					end
				when 6
					away = Team.find_by_abbr(text)
					if away == nil
						puts text
					end
					if teams_used.include?(away)
						seen = true
					else
						seen = false
					end
					away, home = setTeams(amp, away, home)
				when 9
					if !seen
						game = Game.create(:year => year, :month => month, :day => day, :num => num, :away_team_id => away.id, :home_team_id => home.id)
						puts game.url
					end
				end
				var += 1

			end
		end
	end

	task :update => :environment do
		require 'nokogiri'
		require 'open-uri'


		def wOBA(year, ubb, hbp, single, double, triple, hr, ab, bb, ibb, sf)
			url = "http://www.fangraphs.com/guts.aspx?type=cn"
			doc = Nokogiri::HTML(open(url))
			bool = false
			cubb = chbp = csingle = cdouble = ctriple = chr = 0
			doc.css(".grid_line_regular").each_with_index do |stat, index|
				if bool || index%14 == 0
					case index%14
					when 0
						if year == stat.text
							bool = true
						end
					when 3
						cubb = stat.text.to_f
					when 4
						chbp = stat.text.to_f
					when 5
						csingle = stat.text.to_f
					when 6
						cdouble = stat.text.to_f
					when 7
						chr = stat.text.to_f
						break
					end
				end
			end
			if (ab + bb - ibb + sf + hbp) != 0
				wOBA = (cubb*ubb + chbp*hbp + csingle*single + cdouble*double + ctriple*triple + chr*hr) / (ab + bb - ibb + sf + hbp)
			else
				wOBA = 0
			end
			return wOBA
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

		def getHref(stat)
			href = stat.child.child['href']
			if href == nil
				href = stat.child['href']
			end
			return href[11..href.index(".")-1]
		end

		year = Time.now.year

		Team.all.each do |team|
			url = "http://www.baseball-reference.com/teams/#{team.abbr}/2015.shtml"
			doc = Nokogiri::HTML(open(url))

			doc.css("#team_batting tbody td").each_with_index do |stat, index|
				text = stat.text
				case index%28
				when 2
					if hitter = Hitter.find_by_name(getName(text))
						href = getHref(stat)
						hitter.update_attributes(:alias => href)
					end
				end

			end

			doc.css("#team_pitching tbody td").each_with_index do |stat, index|
				text = stat.text
				case index%34
				when 2
					if pitcher = Pitcher.find_by_name(getName(text))
						href = getHref(stat)
						pitcher.update_attributes(:alias => href)
					end
				end
			end
		end

		Hitter.all.each do |hitter|
			if hitter.alias == nil
				next
			end
			url = "http://www.baseball-reference.com/players/split.cgi?id=#{hitter.alias}&year=#{year}&t=b"
			doc = Nokogiri::HTML(open(url))


			wOBA = h = hbp = sf = ibb = single = double = triple = hr = ab = sb = obp = slg = bb = so = 0
			row = 1
			doc.css("#total td").each_with_index do |stat, index|
				text = stat.text
				case index%29
				when 5
					ab = text.to_i
				when 7
					h = text.to_i
				when 8
					double = text.to_i
				when 9
					triple = text.to_i
				when 10
					ht = text.to_i
					single = h - double - triple - hr
				when 12
					sb = text.to_i
				when 14 
					bb = text.to_i
				when 15
					so = text.to_i
				when 17
					obp = (text.to_f*1000).to_i
				when 18
					slg = (text.to_f*1000).to_i
				when 22
					hbp = text.to_i
				when 24
					sf = text.to_i
				when 25
					ibb = text.to_i
					ubb = bb - ibb
					wOBA = wOBA(year, ubb, hbp, single, double, triple, hr, ab, bb, ibb, sf)
					case row
					when 3
						hitter.update_attributes(:AB_14 => ab, :SB_14 => sb, :BB_14 => bb, :SO_14 => so, :SLG_14 => slg, :OBP_14 => obp, :wOBA_14 => wOBA)
						break
					end
					row += 1
				end
			end

			row = 1
			doc.css("#plato td").each_with_index do |stat, index|
				text = stat.text
				case index%29
				when 5
					ab = text.to_i
				when 7
					h = text.to_i
				when 8
					double = text.to_i
				when 9
					triple = text.to_i
				when 10
					hr = text.to_i
					single = h - double - triple - hr
				when 12
					sb = text.to_i
				when 14 
					bb = text.to_i
				when 15
					so = text.to_i
				when 17
					obp = (text.to_f*1000).to_i
				when 18
					slg = (text.to_f*1000).to_i
				when 22
					hbp = text.to_i
				when 24
					sf = text.to_i
				when 25
					ibb = text.to_i
					ubb = bb - ibb
					wOBA = wOBA(year, ubb, hbp, single, double, triple, hr, ab, bb, ibb, sf)
					case row
					when 1
						hitter.update_attributes(:AB_R => ab, :SB_R => sb, :BB_R => bb, :SO_R => so, :SLG_R => slg, :OBP_R => obp, :wOBA_R => wOBA)
					when 2
						hitter.update_attributes(:AB_L => ab, :SB_L => sb, :BB_L => bb, :SO_L => so, :SLG_L => slg, :OBP_L => obp, :wOBA_L => wOBA)
						break
					end
					row += 1
				end
			end
		end

		url_l = ["http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=1&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=21&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=10&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=14&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=16&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=23&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=28&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=17&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=15&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=22&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=30&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=5&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=11&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=20&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=25&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=24&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=2&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=29&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=26&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=27&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=13&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=12&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=3&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=18&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=19&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=7&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=6&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=8&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=4&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=13&season1=#{year}&ind=0&team=9&rost=1&age=0&filter=&players=0"]
		url_r = ["http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=1&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=21&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=10&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=14&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=16&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=23&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=28&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=17&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=15&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=22&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=30&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=5&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=11&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=20&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=25&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=24&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=2&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=29&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=26&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=27&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=13&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=12&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=3&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=18&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=19&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=7&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=6&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=8&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=4&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year}&month=14&season1=#{year}&ind=0&team=9&rost=1&age=0&filter=&players=0"]
		url_14 = ["http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=1&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=21&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=10&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=14&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=16&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=23&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=28&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=17&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=15&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=22&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=30&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=5&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=11&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=20&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=25&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=24&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=2&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=29&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=26&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=27&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=13&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=12&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=3&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=18&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=19&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=7&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=6&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=8&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=4&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,61&season=#{year}&month=2&season1=#{year}&ind=0&team=9&rost=1&age=0&filter=&players=0"]
		url_previous_l = ["http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=1&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=21&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=10&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=14&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=16&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=23&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=28&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=17&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=15&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=22&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=30&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=5&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=11&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=20&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=25&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=24&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=2&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=29&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=26&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=27&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=13&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=12&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=3&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=18&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=19&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=7&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=6&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=8&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=4&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=9&rost=1&age=0&filter=&players=0"]
		url_previous_r = ["http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=1&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=21&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=10&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=14&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=16&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=23&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=28&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=17&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=15&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=22&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=30&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=5&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=11&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=20&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=25&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=24&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=2&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=29&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=26&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=27&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=13&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=12&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=3&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=18&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=19&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=7&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=6&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=8&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=4&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,43,54&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=9&rost=1&age=0&filter=&players=0"]
		
		urls = url_l + url_r + url_14 + url_previous_l + url_previous_r

		wRC = ld = hitter = name = nil
		urls.each_with_index do |url, url_index|
			doc = Nokogiri::HTML(open(url))
			doc.css(".grid_line_regular").each_with_index do |stat, index|
				text = stat.text
				case index%5
				when 1
					name = text
					hitter = Hitter.find_by_name(name)
				when 3
					ld = text[0...-2].to_f
					puts ld
				when 4
					wRC = text.to_i
					if hitter != nil
						case url_index/30
						when 0
							hitter.update_attributes(:team_id => url_index + 1, :LD_L => ld, :wRC_L => wRC)
						when 1
							hitter.update_attributes(:LD_R => ld, :wRC_R => wRC)
						when 2
							hitter.update_attributes(:LD_14 => ld, :wRC_14 => wRC)
						when 3
							hitter.update_attributes(:LD_previous_L => ld, :wRC_previous_L => wRC)
						when 4
							hitter.update_attributes(:LD_previous_R => ld, :wRC_previous_R => wRC)
						end
					else
						puts name + ' not found'
					end
				end
			end
		end

		url = ["http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=1&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=21&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=10&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=14&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=16&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=23&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=28&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=17&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=15&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=22&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=30&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=5&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=11&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=20&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=25&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=24&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=2&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=29&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=26&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=27&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=13&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=12&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=3&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=18&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=19&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=7&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=6&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=8&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=4&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=9&rost=1&age=0&filter=&players=0"]
		url_l = ["http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=1&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=21&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=10&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=14&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=16&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=23&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=28&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=17&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=15&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=22&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=30&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=5&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=11&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=20&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=25&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=24&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=2&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=29&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=26&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=27&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=13&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=12&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=3&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=18&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=19&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=7&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=6&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=8&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=4&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=13&season1=#{year}&ind=0&team=9&rost=1&age=0&filter=&players=0"]
		url_r = ["http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=1&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=21&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=10&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=14&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=16&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=23&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=28&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=17&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=15&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=22&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=30&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=5&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=11&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=20&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=25&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=24&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=2&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=29&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=26&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=27&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=13&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=12&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=3&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=18&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=19&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=7&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=6&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=8&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=4&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47&season=#{year}&month=14&season1=#{year}&ind=0&team=9&rost=1&age=0&filter=&players=0"]
		url_30 = ["http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=1&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=21&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=10&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=14&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=16&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=23&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=28&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=17&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=15&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=22&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=30&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=5&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=11&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=20&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=25&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=24&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=2&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=29&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=26&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=27&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=13&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=12&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=3&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=18&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=19&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=7&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=6&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=8&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=4&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=9&rost=1&age=0&filter=&players=0"]
		url_previous = ["http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=1&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=21&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=10&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=14&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=16&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=23&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=28&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=17&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=15&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=22&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=30&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=5&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=11&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=20&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=25&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=24&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=2&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=29&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=26&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=27&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=13&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=12&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=3&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=18&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=19&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=7&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=6&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=8&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=4&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=9&rost=1&age=0&filter=&players=0"]
		url_previous_l = ["http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=1&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=21&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=10&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=14&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=16&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=23&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=28&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=17&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=15&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=22&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=30&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=5&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=20&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=25&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=24&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=2&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=29&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=26&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=27&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=13&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=12&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=3&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=18&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=19&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=7&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=6&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=8&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=4&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=9&rost=1&age=0&filter=&players=0"]
		url_previous_r = ["http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=1&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=21&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=10&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=14&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=16&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=23&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=28&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=17&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=15&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=22&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=30&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=5&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=20&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=25&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=24&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=2&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=29&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=26&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=27&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=13&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=12&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=3&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=18&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=19&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=7&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=6&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=8&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=4&rost=1&age=0&filter=&players=0", "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=9&rost=1&age=0&filter=&players=0"]

		fip = name = nil
		urls = url + url_previous
		urls.each_with_index do |url, url_index|
			doc = Nokogiri::HTML(open(url))
			doc.css(".grid_line_regular").each_with_index do |stat, index|
				text = stat.text
				case index%4
				when 1
					name = text
				when 3
					fip = text.to_i
					if pitcher = Pitcher.find_by_name(name)
						case url_index%30
						when 0
							pitcher.update_attributes(:team_id => url_index + 1, :FIP => fip)
						when 1
							pitcher.update_attributes(:FIP_previous => fip)
						end
		 			else
		 				puts name + ' not found'
		 			end
				end
		 	end
		end


		urls = url_l + url_r

		ld = whip = ip = so = bb = era = fb = xfip = kbb = woba = nil
		urls.each_with_index do |url, url_index|
			doc = Nokogiri::HTML(open(url))
			doc.css(".grid_line_regular").each do |stat, index|
				text = stat.text
				case index%13
				when 1
					name = text
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
					if pitcher = Pitcher.find_by_name(name)
						case url_index/30
						when 0
							pitcher.update_attributes(:team_id => url_index + 1, :LD_L => ld, :WHIP_L => whip, :IP_L => ip, :SO_L => so, :BB_L => bb, :ERA_L => era, :FB_L => fb, :xFIP_L => xfip, :KBB_L => kbb, :wOBA_L => wOBA)
						when 1
							pitcher.update_attributes(:LD_R => ld, :WHIP_R => whip, :IP_R => ip, :SO_R => so, :BB_R => bb, :ERA_R => era, :FB_R => fb, :xFIP_R => xfip, :KBB_R => kbb, :wOBA_R => wOBA)
						end
					else
						puts name + ' not found'
					end
				end
			end
		end

		url_30.each do |url|
			doc = Nokogiri::HTML(open(url))
			name = ld = whip = ip = so = bb = nil
			doc.css(".grid_line_regular").each_with_index do |stat, index| #Search through all the information. Use an instance variable to determine which information I want.
				text = stat.text
				case index%8
				when 1
					name = text
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
					if pitcher = Pitcher.find_by_name(name)
						pitcher.update_attributes(:LD_30 => ld, :WHIP_30 => whip, :IP_30 => ip, :SO_30 => so, :BB_30 => bb)
					else
						puts name + ' not found'
					end
				end
			end
		end

		urls = url_previous_l + url_previous_r
		name = fb = xfip = kbb = wOBA = ld = whip = ip = so = bb = nil
		urls.each_with_index do |url, url_index|
			doc = Nokogiri::HTML(open(url))
			doc.css(".grid_line_regular").each_with_index do |stat, index|
				text = stat.text
				case index%11
				when 1
					name = text
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
					if pitcher = Pitcher.find_by_name(name)
						case url_index/30
						when 0
							pitcher.update_attributes(:team_id => url_index + 1, :FB_previous_L => fb, :xFIP_previous_L => xfip, :KBB_previous_L => kbb, :wOBA_previous_L => wOBA)
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

		def convertTime(game, time)
			if !time.include?(":")
				return ""
			end
			hour = time[0...time.index(":")].to_i + game.home_team.timezone
			return hour.to_s + time[time.index(":")..-4]
		end

		url = "http://www.baseballpress.com/lineups/#{DateTime.now.to_date}"
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

		year = Time.now.year.to_s
		month = Time.now.month.to_s
		day = Time.now.day.to_s
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
	end

	task :starters => :environment do
		require 'nokogiri'
		require 'open-uri'

		def starters()
			Pitcher.all.where(:starter => true).each do |pitcher|
				pitcher.update_attributes(:starter => false)
			end
			Hitter.all.where(:starter => true).each do |hitter|
				hitter.update_attributes(:starter => false)
			end
		end

		def nicknames(text)
			case text
			when 'Nathan Karns'
				return 'Nate Karns'
			when 'Matt Joyce'
				return 'Matthew Joyce'
			when 'Jackie Bradley Jr.'
				return 'Jackie Bradley'
			when 'Steven Souza Jr.'
				return 'Steven Souza'
			end
		end

		starters()

		url = "http://www.baseballpress.com/lineups/#{DateTime.now.to_date}"
		doc = Nokogiri::HTML(open(url))
		
		pitchers = Pitcher.where(:game_id => nil)
		doc.css(".team-name+ div").each do |player|
			text = player.text
			if text == "TBD"
				next
			end
			text = text[0...-4]
			if pitcher = pitchers.find_by_name(text)
				pitcher.update_attributes(:starter => true)
			elsif pitcher = pitchers.find_by_name(nicknames(text))
				pitcher.update_attributes(:starter => true)
			else
				puts 'Could not find pitcher ' + text
			end
		end

		hitters = Hitter.where(:game_id => nil)
		doc.css(".players div").each do |player|
			text = player.text
			lineup = text[0].to_i
			text = text[3..text.index(")")-4]
			if hitter = hitters.find_by_name(text)
				hitter.update_attributes(:starter => true, :lineup => lineup)
			elsif hitter = hitters.find_by_name(nicknames(text))
				hitter.update_attributes(:starter => true, :lineup => lineup)
			else
				puts 'Could not find hitter ' + text
			end
		end
	end

	task :bullpen => :environment do
		require 'nokogiri'
		require 'open-uri'

		def bullpen()
			Pitcher.where(:bullpen => true).each do |pitcher|
				pitcher.update_attributes(:bullpen => false)
			end
		end

		def nicknames(text)
			case text
			when 'Nate Adcock'
				return 'Nathan Adcock'
			when 'Robbie Ross Jr.'
				return 'Robbie Ross'
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
			puts text
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
				if pitcher = pitchers.find_by_name(text)
				elsif pitcher = pitchers.find_by_name(nicknames(text))
				else
					puts 'Bullpen pitcher ' + text + ' not found'
					pitcher = nil
				end
				var = 1
			end

		end	

		if @pitcher
			@pitcher.update_attributes(:bullpen => true, :one => @one, :two => @two, :three => @three)
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
					Game.where(:year => year, :month => month, :day => day, :home_team_id => team.id).first.update_attributes(:ump => ump)
				end
			end
		end
	end

	task :add => :environment do
		
	end

end