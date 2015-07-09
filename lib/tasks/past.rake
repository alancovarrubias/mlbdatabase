namespace :past do

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

				case var%21
				when 2
					month, day = convertDate(text)
					if text.include?('(')
						num = text[-2]
					else
						num = '0'
					end
					if month.to_i > 6 || (month.to_i == 7 && day.to_i >= 5)
						break
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
	
	task :lineups => :environment do
		require 'nokogiri'
		require 'open-uri'


		games = Game.where("month < '07' OR (month = '07' AND day < '06')")

		games.each do |game|
			url = "http://www.baseball-reference.com/boxes/#{game.home_team.game_abbr}/#{game.url}.shtml"
			puts url

			doc = Nokogiri::HTML(open(url))

			int = 22
			table = var = row = 0
			team_id = player = nil
			hitters = Hitter.where(:game_id => nil)
			pitchers = Pitcher.where(:game_id => nil)
			doc.css(".normal_text td").each do |stat|
				text = stat.text
				case var%int
				when 0
					row += 1
					if table%2 == 0
						team_id = game.away_team.id
					else
						team_id = game.home_team.id
					end
					child = stat.last_element_child
					if table == 2
						int = 25
						var = 0
					end
					if child == nil # This is a total, so a new table is near
						row = 0
						table += 1
					else
						href = child['href']
						href = href[11..href.index(".")-1]
						if table < 2 # we are still at the hitting tables
							player = hitters.find_by_alias(href)
						else # we are at the pitching tables
							player = pitchers.find_by_alias(href)
						end

						if player != nil
							if row <= 9 && player.class.name == "Hitter"
								Hitter.create(:game_id => game.id, :team_id => team_id, :starter => true, :name => player.name, :alias => player.alias, :fangraph_id => player.fangraph_id, :lineup => row)
							elsif row == 1 && player.class.name == "Pitcher"
								Pitcher.create(:game_id => game.id, :team_id => team_id, :starter => true, :name => player.name, :alias => player.alias, :fangraph_id => player.fangraph_id)
							end
						else
							puts href + ' not found'
						end
					end
				end
				var += 1
			end
		end
	end

	task :time => :environment do
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


		today = Time.now.yesterday.yesterday.yesterday
		while true
			today = today.yesterday
			year = today.year.to_s
			month = today.month.to_s
			day = today.day.to_s

			if month == '3'
				break
			end

			if month.size == 1
				month = "0" + month
			end

			if day.size == 1
				day = "0" + day
			end


			url = "http://www.baseballpress.com/lineups/#{year}-#{month}-#{day}"
			doc = Nokogiri::HTML(open(url))
			puts url
			games = Game.where(:year => year, :month => month, :day => day)
			puts games.size

			time = home = 0
			doc.css(".game-time , .team-name").each_with_index do |stat, index|
				case index%3
				when 0
					time = stat.text
				when 2
					if time == "PPD"
						next
					end
					home = Team.find_by_name(stat.text)
					game = games.where(:home_team_id => home.id).first
					puts home.name
					if game == nil
						puts home.name + ' skipped'
						next
					end
					game.update_attributes(:time => convertTime(game, time))
				end
			end
		end

	end

	task :innings => :environment do
		require 'nokogiri'
		require 'open-uri'

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

		games.each do |game|

			if game.innings.size != 0
				next
			end

			url = "http://www.baseball-reference.com/boxes/#{game.home_team.game_abbr}/#{game.url}.shtml"
			doc = Nokogiri::HTML(open(url))

			docs = doc.css("#linescore").first

			if docs == nil
				puts url + ' did not work'
				next
			else
				puts url
				text = docs.text
			end

			newline = text.index("\n")
			innings = text[0...newline]
			text = text[newline+1..-1]
			newline = text.index("\n")
			dashes = text[0...newline]
			text = text[newline+1..-1]
			newline = text.index("\n")
			away = text[0...newline]
			text = text[newline+1..-1]
			newline = text.index("\n")
			home = text[0...newline]


			num = 15
			innings = innings[num..-1]
			dashes = dashes[num..-1]
			away = away[num..-1]
			home = home[num..-1]

			inning_array = Array.new
			away_array = Array.new
			home_array = Array.new

			(0...innings.size).each do |i|
				if dashes[i] == '-'
					if innings[i-1] != ' '
						inning_array << innings[i-1] + innings[i]
					else
						inning_array << innings[i]
					end
					if away[i-1] != ' '
						away_array << away[i-1] + away[i]
					else
						away_array << away[i]
					end
					if home[i-1] != ' '
						home_array << home[i-1] + home[i]
					else
						home_array << home[i]
					end
				end
			end

			(0...inning_array.size).each do |i|
				Inning.create(:game_id => game.id, :number => inning_array[i], :away => away_array[i], :home => home_array[i])
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

		games = Game.where("month < '07' OR (month < '07' AND day = '07')")
		nil_pitchers = Pitcher.where(:game_id => nil)
		nil_hitters = Hitter.where(:game_id => nil)

		games.each do |game|

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

	task :delete_games => :environment do
		# games = Game.where("month < '07' OR (month = '07' AND day < '06')").each do |game|
		games = Game.where(:year => '2015', :month => '07', :day => '07').each do |game|
			game.pitchers.destroy_all
			game.hitters.destroy_all
		end

	end

	task :delete_players => :environment do
		games = Game.where(:year => '2015', :month => '07', :day => '06').each do |game|
			game.pitchers.destroy_all
			game.hitters.destroy_all
		end
	end

	task :null => :environment do
		Hitter.where(:game_id => nil).each do |hitter|
			hitter.update_attributes(:fangraph_id => 0)
		end

		Pitcher.where(:game_id => nil).each do |pitcher|
			pitcher.update_attributes(:fangraph_id => 0)
		end
	end

	task :test => :environment do
		require 'nokogiri'
		require 'open-uri'
		games = Game.where("month < '07' OR (month < '07' AND day = '07')")
		games.each do |game|

			if game.innings.size != 0
				next
			end

			url = "http://www.baseball-reference.com/boxes/#{game.home_team.game_abbr}/#{game.url}.shtml"
			doc = Nokogiri::HTML(open(url))

			docs = doc.css("#linescore").first

			if docs == nil
				puts url + ' deleted'
				game.pitchers.destroy_all
				game.hitters.destroy_all
				game.destroy
			else
				puts url
			end

		end

	end

	task :whoo => :environment do
		require 'nokogiri'
		require 'open-uri'

		url = "http://www.fangraphs.com/boxscore.aspx?date=2015-05-25&team=Orioles&dh=0&season=2015"
		doc = Nokogiri::HTML(open(url))
		doc.css("#WinsBox1_dgab_ctl00 .grid_line_regular").each do |stat|
			puts stat.child.text
		end

	end

end