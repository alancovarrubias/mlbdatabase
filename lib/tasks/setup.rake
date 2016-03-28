namespace :setup do

	require 'nokogiri'
	require 'open-uri'

	task :delete => :environment do
		Game.games(Time.now).each do |game|
			game.pitchers.destroy_all
			game.hitters.destroy_all
			game.destroy
		end
	end

	task :create => [:create_teams, :create_players] do
	end

	task :daily => [:create_players, :fangraphs, :update_players, :boxscores, :innings] do
	end

	task :hourly => [:update_weather, :bullpen, :matchups, :ump, :tomorrow, :closingline] do
	end

	task :create_teams => :environment do
		include Create
		Create.teams
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

	task :fangraphs => :environment do
		Team.all.each do |team|
			team.fangraphs
		end
	end

	task :update_weather => :environment do
		include Matchup
		hour, day, month, year = Matchup.find_date(Time.now)
		if hour > 6 && hour < 23
			Game.where(:year => year, :month => month, :day => day).each do |game|
				game.update_weather_forecast(true)
				game.update_weather
			end

			hour, day, month, year = Matchup.find_date(Time.now.tomorrow)
			Game.where(:year => year, :month => month, :day => day).each do |game|
				game.update_weather_forecast(false)
			end
		end
	end

	task :matchups => :environment do
		include Matchup
		# Today's current lineup from baseballpress
		url = "http://www.baseballpress.com/lineups/#{DateTime.now.to_date}"
		puts url
		doc = Nokogiri::HTML(open(url))
		hour, day, month, year = find_date(Time.now)
		todays_games = Game.where(:year => year, :month => month, :day => day)
		proto_pitchers = Pitcher.where(:game_id => nil)
		proto_hitters = Hitter.where(:game_id => nil)
		home, away, gametime, duplicates = set_game_info(doc)
		create_games(todays_games, gametime, home, away, duplicates, Time.now)
		todays_games = Game.where(:year => year, :month => month, :day => day)
		set_starters_false(proto_pitchers, proto_hitters)
		create_game_starters(doc, todays_games)

		if hour > 6 && hour < 23
			create_bullpen_pitchers(todays_games, proto_pitchers, proto_hitters)
		end
		remove_excess_starters(todays_games, proto_pitchers, proto_hitters)
	end


	task :tomorrow => :environment do

		include Matchup

		url = "http://www.baseballpress.com/lineups/#{DateTime.now.tomorrow.to_date}"
		puts url
		doc = Nokogiri::HTML(open(url))
		hour, day, month, year = find_date(Time.now.tomorrow)
		tomorrows_games = Game.where(:year => year, :month => month, :day => day)
		home, away, gametime, duplicates = set_game_info(doc)
		create_games(tomorrows_games, gametime, home, away, duplicates, Time.now.tomorrow)
		set_tomorrow_starters_false
		proto_pitchers = Pitcher.where(:game_id => nil)
		set_tomorrow_starters(doc, proto_pitchers, away, home)

	end

	task :ump => :environment do
		include Matchup
		url = "http://www.statfox.com/mlb/umpiremain.asp"
		doc = Nokogiri::HTML(open(url))
		set_umpire(doc)
	end

	task :bullpen => :environment do
		include Matchup
		hour = Time.now.hour
		if hour > 6 && hour < 23
			set_bullpen
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

		hour, day, month, year = find_date(Time.now.yesterday)

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

	task :innings => :environment do
		require 'nokogiri'
		require 'open-uri'

		hour, day, month, year = find_date(Time.now.yesterday)

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

	task :closingline => :environment do
		require 'nokogiri'
		require 'open-uri'
		include Matchup
		hour, day, month, year = Matchup.find_date(Time.now)
		if hour > 6 && hour < 22
			today_games = Game.where(:year => year, :month => month, :day => day)
			size = today_games.size
			url = "http://www.sportsbookreview.com/betting-odds/mlb-baseball/?date=#{year}#{month}#{day}"
			puts url
			doc = Nokogiri::HTML(open(url))
			game_array = Array.new
			doc.css(".team-name a").each_with_index do |stat, index|
				if index == size*2
					break
				end
				if index%2 == 1
					abbr = stat.child.text
					case abbr
					when "TB"
						abbr = "TBR"
					when "SF"
						abbr = "SFG"
					when "SD"
						abbr = "SDP"
					when "CWS"
						abbr = "CHW"
					when "KC"
						abbr = "KCR"
					when "WSH"
						abbr = "WSN"
					end
					team = Team.find_by_abbr(abbr)
					if team == nil
						game_array << nil
						next
					end
					games = today_games.where(:home_team_id => team.id)
					if games.size == 2
						if game_array.include?(games.first)
							game_array << games.second
						else
							game_array << games.first
						end
					elsif games.size == 1
						game_array << games.first
					else
						game_array << nil
					end
						
				end
			end

			away_money_line = Array.new
			home_money_line = Array.new
			doc.css(".eventLine-consensus+ .eventLine-book b").each_with_index do |stat, index|
				if index == size*2
					break
				end
				if index%2 == 0
					away_money_line << stat.text
				else
					home_money_line << stat.text
				end
			end

			away_totals = Array.new
			home_totals = Array.new
			url = "http://www.sportsbookreview.com/betting-odds/mlb-baseball/totals/"
			doc = Nokogiri::HTML(open(url))
			doc.css(".eventLine-consensus+ .eventLine-book b").each_with_index do |stat, index|
				if index == size*2
					break
				end
				if index%2 == 0
					away_totals << stat.text
				else
					home_totals << stat.text
				end
			end

			(0...size).each do |i|
				game = game_array[i]
				if game != nil
					game.update_attributes(:away_money_line => away_money_line[i], :home_money_line => home_money_line[i], :away_total => away_totals[i], :home_total => home_totals[i])
				end
			end
		end

	end

	task :find_missing => :environment do
		include Matchup

		hour, day, month, year = Matchup.find_date(Time.now)

		Game.where(:year => year, :month => month, :day => day).each do |game|
			pitchers_size = game.pitchers.where(:starter => true).size
			unless pitchers_size == 2
				puts game.home_team.name + ' have ' + pitchers_size.to_s + ' pitchers'
			end
			hitters_size = game.hitters.where(:starter => true).size
			unless hitters_size == 18
				puts game.home_team.name + ' have ' + hitters_size.to_s + ' hitters'
			end
		end

		hour, day, month, year = Matchup.find_date(Time.now.tomorrow)

		Game.where(:year => year, :month => month, :day => day).each do |game|
			pitchers_size = (Pitcher.where(:tomorrow_starter => true, :team_id => game.home_team.id) + Pitcher.where(:tomorrow_starter => true, :team_id => game.away_team.id)).size
			if pitchers_size != 2
				puts game.home_team.name + ' have ' + pitchers_size.to_s + ' tomorrow pitchers'
			end
		end
	end

end