module Update
  class Pitchers

  	attr_accessor :season, :team

  	def initialize(season, team)
  		@season = season
  		@team = team
  	end

  	def update_stat
  		year = season.year
  		puts "Update " + team.name + " " + year.to_s + " Pitchers"

	  	url = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=1&season=#{year}&month=0&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=0&age=0&filter=&players=0&page=1_50"
	  	doc = download_document(url)
	  	player = name = nil
	  	doc.css(".grid_line_regular").each_with_index do |element, index|
	  	  text = element.text
	  	  case index%16
	  	  when 1
	  	  	name = text
	  	    fangraph_id = parse_fangraph_id(element)
	  	    player = Player.search(name, nil, fangraph_id)
	  	    unless player
	  	      puts "Player " + name + " not found" 
	  	    end
	  	  when 11
	  	  	fip = text.to_i
	  	  	if player
	  	  	  lancer = player.create_lancer(season)
	  	  	  lancer.stats.each_with_index do |pitcher_stat|
	  	  	  	if pitcher_stat.handedness.size > 0
	  	  	  	  pitcher_stat.update_attributes(fip: fip)
	  	  	  	end
	  	  	  end
	  	  	end
	  	  end
	  	end

	  	url_l = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47,37&season=#{year}&month=13&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=0&age=0&filter=&players=0&page=1_50"
			url_r = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47,37&season=#{year}&month=14&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=0&age=0&filter=&players=0&page=1_50"
			urls = [url_l, url_r]
			player = name = ld = whip = ip = so = bb = era = fb = xfip = kbb = woba = gb = nil
			urls.each_with_index do |url, url_index|
			  doc = download_document(url)
			  doc.css(".grid_line_regular").each_with_index do |element, index|
			    text = element.text
			    case index%13
			    when 1
				  	name = text
			  	  fangraph_id = parse_fangraph_id(element)
			  	  player = Player.search(name, nil, fangraph_id)
			  	  unless player
			  	    puts "Player " + name + " not found" 
			  	  end
			  	when 2
			  	  ld = text[0...-2].to_f
					when 3
					  whip = text.to_f
					when 4
					  ip = text.to_f
					when 5
					  so = text.to_i
					when 6
					  bb = text.to_i
					when 7
					  era = text.to_f
					when 8
					  fb = text[0...-2].to_f
					when 9
					  xfip = text.to_i
					when 10
					  kbb = text.to_f
					when 11
					  woba = (text.to_f*1000).to_i
					when 12
					  gb = text[0...-2].to_f
					  if player
					  	handedness = get_handedness(url_index)
					  	lancer = player.create_lancer(season)
					  	pitcher_stat = lancer.stats.where(handedness: handedness).first
					  	pitcher_stat.update_attributes(ld: ld, whip: whip, ip: ip, so: so, bb: bb, era: era, fb: fb, xfip: xfip, kbb: kbb, woba: woba, gb: gb)
					  end
					end
			  end
			end

			url = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=0&age=0&filter=&players=0&page=1_50"
			doc = download_document(url)
			name = ld = whip = ip = so = bb = nil
			doc.css(".grid_line_regular").each_with_index do |element, index|
			  text = element.text
			  case index%7
			  when 1
					name = text
			  	fangraph_id = parse_fangraph_id(element)
			  	player = Player.search(name, nil, fangraph_id)
			  	unless player
			  	  puts "Player " + name + " not found" 
			  	end
			  when 2
					ld = text[0...-2].to_f
			  when 3
					whip = text.to_f
			  when 4
					ip = text.to_f
			  when 5
					so = text.to_i
			  when 6
					bb = text.to_i
					if player
					  lancer = player.create_lancer(season)
					  pitcher_stat = lancer.stats.where(handedness: "").first
					  pitcher_stat.update_attributes(ld: ld, whip: whip, ip: ip, so: so, bb: bb)
					end
			  end
			end

			team.players.each do |player|
	  	  if player.identity == "" || player.find_lancer(season) == nil
	  	  	next
	  	  end
	  	  url = "http://www.baseball-reference.com/players/split.cgi?id=#{player.identity}&year=#{year}&t=p"
	  	  doc = download_document(url)
	  	  row = 0
	  	  doc.css("#plato td").each_with_index do |element, index|
	  	  	case index%28
	  	  	when 27
	  	  	  ops = element.text.to_i
	  	  	  case row
	  	  	  when 0
	  	  	  	player.create_lancer(season).stats.where(handedness: "R").first.update_attributes(ops: ops)
	  	  	  when 1
	  	  	  	player.create_lancer(season).stats.where(handedness: "L").first.update_attributes(ops: ops)
	  	  	  end
	  	  	  row += 1
	  	  	end
	  	  	if row == 2
	  	  	  break
	  	  	end
	  	  end
	  	end
	  end


    def game_pitchers(game_day)
      game_day.games.each do |game|
      	@pitchers = Array.new
		    url = "http://www.baseball-reference.com/boxes/#{game.home_team.game_abbr}/#{game.url}.shtml"
		    puts url
		    doc = download_document(url)
		    team_pitchers(doc, game, game.away_team)
		    team_pitchers(doc, game, game.home_team)
		    player_ids = @pitchers.map { |player| player.id }
		    game.lancers.where(starter: true).each do |lancer|
		      unless player_ids.include? lancer.player_id
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
					  	@pitchers << player
					  	lancer = game.lancers.where(starter: true).find_by(player_id: player.id)
					  	unless lancer
					  	  lancer = player.create_lancer(game.game_day.season, team, game)
					  	  lancer.update(starter: true)
					  	end
				  	    # puts lancer.player.name
			  		    lancer.update(ip: ip, h: h, r: r, bb: bb)
					  end
					  break
					end
			  end
			end

  end
end