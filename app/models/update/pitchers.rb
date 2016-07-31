module Update
  class Pitchers

  	include NewShare

  	def update(season, team)
  		year = season.year
  		puts "Update #{team.name} #{year} Pitchers"

  		(0..1).each do |rost|
		  	url = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=1&season=#{year}&month=0&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=#{rost}&age=0&filter=&players=0&page=1_50"
		  	doc = download_document(url)
		  	puts url
		  	index = { name: 1, fip: 11+rost, siera: 15+rost }
		  	doc.css(".grid_line_regular").each_slice(16+rost) do |slice|
		  		name = slice[index[:name]].text
		  		fangraph_id = parse_fangraph_id(slice[index[:name]])
		  		player = Player.search(name, nil, fangraph_id)
		  		puts "Player " + name + " not found" unless player
		  		fip = slice[index[:fip]].text.to_f
		  		siera = slice[index[:siera]].text.to_f
		  		if player
	  	  	  lancer = player.create_lancer(season)
	  	  	  lancer.stats.each_with_index do |pitcher_stat|
	  	  	  	if pitcher_stat.handedness.size > 0
	  	  	  	  pitcher_stat.update(fip: fip, siera: siera)
	  	  	  	end
	  	  	  end
		  		end
		  	end


		  	url_l = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47,37&season=#{year}&month=13&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=#{rost}&age=0&filter=&players=0&page=1_50"
				url_r = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47,37&season=#{year}&month=14&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=#{rost}&age=0&filter=&players=0&page=1_50"
				urls = [url_l, url_r]
				player = name = ld = whip = ip = so = bb = era = fb = xfip = kbb = woba = gb = nil
				urls.each_with_index do |url, url_index|
					doc = download_document(url)
					index = { name: 1, ld: 2 + rost, whip: 3 + rost, ip: 4 + rost, so: 5 + rost, bb: 6 + rost, era: 7 + rost, fb: 8 + rost, xfip: 9 + rost,
						kbb: 10 + rost, woba: 11 + rost, gb: 12 + rost }
					doc.css(".grid_line_regular").each_slice(13+rost) do |slice|
						name = slice[index[:name]].text
						fangraph_id = parse_fangraph_id(slice[index[:name]])
						player = Player.search(name, nil, fangraph_id)
						unless player
							puts "Player " + name + " not found"
							next
						end
						ld = slice[index[:ld]].text[0...-2].to_f
						whip = slice[index[:whip]].text.to_f
						ip = slice[index[:ip]].text.to_f
						so = slice[index[:so]].text.to_f
						bb = slice[index[:bb]].text.to_f
						era = slice[index[:era]].text.to_f
						fb = slice[index[:fb]].text[0...-2].to_f
						xfip = slice[index[:xfip]].text.to_f
						kbb = slice[index[:kbb]].text.to_f
						woba = (slice[index[:woba]].text.to_f*1000).to_i
						gb = slice[index[:gb]].text[0...-2].to_f
				  	handedness = get_handedness(url_index)
				  	lancer = player.create_lancer(season)
				  	pitcher_stat = lancer.stats.where(handedness: handedness).first
				  	pitcher_stat.update_attributes(ld: ld, whip: whip, ip: ip, so: so, bb: bb, era: era, fb: fb, xfip: xfip, kbb: kbb, woba: woba, gb: gb)
					end
				end

				# No handedness
				url = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19,122&season=#{year}&month=3&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=#{rost}&age=0&filter=&players=0&page=1_50"
				doc = download_document(url)
				name = ld = whip = ip = so = bb = siera = nil
				index = { name: 1, ld: 2 + rost, whip: 3 + rost, ip: 4 + rost, so: 5 + rost, bb: 6 + rost, siera: 7 + rost }
				doc.css(".grid_line_regular").each_slice(8+rost) do |slice|
					name = slice[index[:name]].text
					fangraph_id = parse_fangraph_id(slice[index[:name]])
					player = Player.search(name, nil, fangraph_id)
					unless player
						puts "Player " + name + " not found" 
						next
					end
					ld = slice[index[:ld]].text[0...-2].to_f
					whip = slice[index[:whip]].text.to_f
					ip = slice[index[:ip]].text.to_f
					so = slice[index[:so]].text.to_i
					bb = slice[index[:bb]].text.to_i
					siera = slice[index[:siera]].text.to_f
				  lancer = player.create_lancer(season)
				  pitcher_stat = lancer.stats.where(handedness: "").first
				  pitcher_stat.update_attributes(ld: ld, whip: whip, ip: ip, so: so, bb: bb, siera: siera)
				end
			end

			team.players.each do |player|
				unless player.find_lancer(season)
					next
				end
	  	  url = "http://www.baseball-reference.com/players/split.cgi?id=#{player.identity}&year=#{year}&t=p"
	  	  doc = download_document(url)
	  	  unless doc
	  	  	puts "#{player.name} not found"
	  	  	next
	  	  end
	  	  row = 0
	  	  doc.css("#plato td").each_slice(28) do |slice|
	  	  	ops = slice[27].text.to_i
	  	  	if row == 0
	  	  		player.create_lancer(season).stats.find_by(handedness: "R").update_attributes(ops: ops)
	  	  	elsif row == 1
	  	  		player.create_lancer(season).stats.find_by(handedness: "L").update_attributes(ops: ops)
	  	  	else
	  	  		break
	  	  	end
	  	  	row += 1
	  	  end
	  	end
	  end


    def box_scores(game_day)
      game_day.games.each do |game|
      	@pitcher_ids = Array.new
		    url = "http://www.baseball-reference.com/boxes/#{game.home_team.game_abbr}/#{game.url}.shtml"
		    puts url
		    doc = download_document(url)
		    return unless doc
		    team_pitchers(doc, game, game.away_team)
		    team_pitchers(doc, game, game.home_team)
		    game.lancers.where(starter: true).each do |lancer|
		      unless @pitcher_ids.include? lancer.player_id
		      	puts "#{lancer.player.name} destroyed"
		      	lancer.destroy
		      end
		    end
		  end
		end

		private

			def parse_identity(element)
			  href = element.child.child['href']
			  if href == nil
					href = element.child['href']
			  end
			  return href[11..href.index(".")-1]
			end

			def team_pitchers(doc, game, team)
			  name = identity = ip = h = r = bb = nil
			  doc.css("##{team.css}pitching tbody td").each_with_index do |element, index|
					case index
					when 0
					  name = element.child.text
					  identity = parse_identity(element)
					when 1
					  ip = element.text.to_f
					when 2
					  h = element.text.to_i
					when 3
					  r = element.text.to_i
					when 5
					  bb = element.text.to_i
					when 6
					  if player = Player.search(name, identity)
					  	@pitcher_ids << player.id
					  	lancer = game.lancers.where(starter: true).find_by(player: player)
					  	unless lancer
					  	  lancer = player.create_lancer(game.game_day.season, team, game)
					  	  lancer.update(starter: true)
					  	end
		  		    lancer.update(ip: ip, h: h, r: r, bb: bb)
					  end
					  break
					end
			  end
			end

		  def parse_fangraph_id(element)
		    href = element.child['href']
		    if href
			  	first = href.index('=')+1
			  	last = href.index('&')
			  	return href[first...last].to_i
		    end
		  end

    	def get_handedness(url_index)
	  	  handedness = nil
	  	  case url_index
	  	  when 0
	  	  	handedness = "L"
	  	  when 1
	  	  	handedness = "R"
	  	  when 2
	  	  	handedness = ""
	  	  end
	  	  return handedness
	  	end

  end
end