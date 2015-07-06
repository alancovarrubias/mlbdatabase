namespace :past do
	task :lineups => :environment do
		require 'nokogiri'
		require 'open-uri'


		games = Game.where("month < '06' OR (month = '06' AND day < '29')")

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

	task :delete_games => :environment do
		games = Game.where("month < '06' OR (month = '06' AND day < '29')").each do |game|
			game.pitchers.destroy_all
			game.hitters.destroy_all
			game.destroy
		end

	end

	task :delete_players => :environment do
		games = Game.where(:year => '2015', :month => '07', :day => '03').each do |game|
			game.pitchers.destroy_all
			game.hitters.destroy_all
		end
	end

end