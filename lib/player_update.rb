module PlayerUpdate

  include NewShare

  def create_players(season, team)
  	year = season.year
  	puts "Create " + team.name + " " + year.to_s + " Players"
  	url = "http://www.baseball-reference.com/teams/#{team.abbr}/#{year}-roster.shtml"
  	doc = download_document(url)
  	modulus = get_modulus(season.year)
	name = identity = bathand = throwhand = nil
	doc.css("#appearances td").each_with_index do |element, index|
	  text = element.text
	  case index%modulus
	  when 0
	  	name = text
	  	identity = parse_identity(element)
	  when 3
	  	bathand = text
	  when 4
	  	throwhand = text
	  when 13
	  	is_pitcher = (text.to_i != 0)
	  	unless player = Player.search(name, identity)
	  	  player = Player.create(name: name, identity: identity)
	  	  puts "Player " + player.name + " created"
	  	end
	  	player.update_attributes(team_id: team.id, identity: identity, bathand: bathand, throwhand: throwhand)
	  	player.create_batter(season)
	  	if is_pitcher
	  	  player.create_lancer(season)
	  	end
	  	check_exceptions(player)
	  end
	end
  end

  # Updates fangraph_ids of players for easier updating
  def fangraphs(team)

	url = "http://www.fangraphs.com/depthcharts.aspx?position=ALL&teamid=#{team.fangraph_id}"
	doc = Nokogiri::HTML(open(url))
	doc.css(".depth_chart:nth-child(58) td").each_with_index do |stat, index|
	  case index%10
	  when 0
		name = stat.child.child.to_s
		unless name.size == 0
		  fangraph_id = parse_fangraph_id(stat)
		  player = Player.search(name, nil, fangraph_id)
		  if player
		  	player.update_attributes(fangraph_id: fangraph_id)
		  else
		  	puts "Player " + name + " not found"
		  end
		end
	  end
	end

	doc.css(".depth_chart:nth-child(76) td").each_with_index do |stat, index|
	  case index%10
	  when 0
	    name = stat.child.child.to_s
	    unless name.size == 0
		  fangraph_id = parse_fangraph_id(stat)
		  player = Player.search(name, nil, fangraph_id)
		  if player
		  	player.update_attributes(fangraph_id: fangraph_id)
		  else
		  	puts "Player " + name + " not found"
		  end
	    end
	  end
	end
  end

  def update_batters(season, team)
  	year = season.year
  	puts "Update " + team.name + " " + year.to_s + " Batters"

    url = "http://www.baseball-reference.com/teams/#{team.abbr}/#{year}.shtml"
    puts url
    doc = download_document(url)
    name = identity = nil
    doc.css("#team_batting tbody td").each_with_index do |stat, index|
      text = stat.text
      case index%28
      when 2
        name = stat.child.child.text
        identity = parse_identity(stat)
      when 21
        ops = text.to_i
        player = Player.search(name, identity)
        if player
          batter = player.create_batter(season)
          batter.stats.each do |stat|
            if stat.handedness.size > 0
              stat.update_attributes(ops: ops)
            end
          end
        else
          puts "Player " + name + " not found"
        end
      end
    end

  	url_l = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,5,21,14,16,38,37,50,54,43,44,45&season=#{year}&month=13&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=0&age=0&filter=&players=0&page=1_50"
  	url_r = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,5,21,14,16,38,37,50,54,43,44,45&season=#{year}&month=14&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=0&age=0&filter=&players=0&page=1_50"
  	url_14 = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,5,21,14,16,38,37,50,61,43,44,45&season=#{year}&month=2&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=0&age=0&filter=&players=0&page=1_50"
  	urls = [url_l, url_r, url_14]
  	urls.each_with_index do |url, url_index|
  	  puts url
  	  doc = download_document(url)
  	  ab = sb = bb = so = slg = obp = woba = wrc = ld = gb = fb = player = name = nil
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
  	  	  ab = text.to_i
  	  	when 3
  	  	  sb = text.to_i
  	  	when 4
  	  	  bb = text.to_i
  	  	when 5
  	  	  so = text.to_i
  	  	when 6
  	  	  slg = (text.to_f*1000).to_i
  	  	when 7
  	  	  obp = (text.to_f*1000).to_i
  	  	when 8
  	  	  woba = (text.to_f*1000).to_i
  	  	when 9
  	  	  wrc = text.to_i
  	  	when 10
  	  	  ld = text[0...-2].to_f
	  	when 11
  	  	  gb = text[0...-2].to_f
	  	when 12
  	  	  fb = text[0...-2].to_f
  	  	  if player
  	  	  	handedness = get_handedness(url_index)
  	  	  	batter = player.create_batter(season)
  	  	  	batter_stat = batter.stats.where(handedness: handedness).first
		  	batter_stat.update_attributes(ab: ab, sb: sb, bb: bb, so: so, slg: slg, obp: obp, woba: woba, wrc: wrc, ld: ld, gb: gb, fb: fb)
  	  	  end
  	  	end
  	  end
  	end
  end

  def update_pitchers(season, team)
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

	# team.players.each do |player|
 #  	  if player.identity == "" || player.find_lancer(season) == nil
 #  	  	next
 #  	  end
 #  	  url = "http://www.baseball-reference.com/players/split.cgi?id=#{player.identity}&year=#{year}&t=p"
 #  	  doc = download_document(url)
 #  	  row = 0
 #  	  doc.css("#plato td").each_with_index do |element, index|
 #  	  	case index%28
 #  	  	when 27
 #  	  	  ops = element.text.to_i
 #  	  	  case row
 #  	  	  when 0
 #  	  	  	player.create_lancer(season).stats.where(handedness: "R").first.update_attributes(ops: ops)
 #  	  	  when 1
 #  	  	  	player.create_lancer(season).stats.where(handedness: "L").first.update_attributes(ops: ops)
 #  	  	  end
 #  	  	  row += 1
 #  	  	end
 #  	  	if row == 2
 #  	  	  break
 #  	  	end
 #  	  end
 #  	end

  end

  private
    def check_exceptions(player)
      if player.name == "Enrique Hernandez"
      	player.update_attributes(fangraph_id: 10472)
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

	def get_modulus(year)
	  if year == Time.now.year
	    modulus = 28
	  else
	    modulus = 29
	  end
	end

	def parse_identity(element)
	  href = element.child.child['href']
	  if href == nil
		href = element.child['href']
	  end
	  return href[11..href.index(".")-1]
	end

	def parse_fangraph_id(element)
	  href = element.child['href']
	  if href
		first = href.index('=')+1
		last = href.index('&')
		return href[first...last].to_i
	  end
	end

end