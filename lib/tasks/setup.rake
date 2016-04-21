namespace :setup do

	task :boxscores => :environment do
		require 'nokogiri'
		require 'open-uri'

		include Share

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

		include Share

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

end