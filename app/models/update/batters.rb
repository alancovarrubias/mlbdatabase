module Update
	class Batters

		include NewShare

	  def update(season, team)
	  	year = season.year
	  	puts "Update #{team.name} #{year} Batters"
	    url = "http://www.baseball-reference.com/teams/#{team.abbr}/#{year}.shtml"
	    puts url
	    doc = download_document(url)
	    name = identity = nil
	    index = { name: 2, identity: 21}
	    doc.css("#team_batting tbody td").each_slice(28) do |slice|
	    	name = slice[index[:name]].child.child.text
	    	identity = parse_identity(slice[index[:name]])
	    	ops = slice[index[:identity]].text.to_i
	    	player = Player.search(name, identity)
	    	if player
          batter = player.create_batter(season)
          batter.stats.each do |stat|
            if stat.handedness.size > 0
              stat.update_attributes(ops: ops)
            end
          end
	    	end
	    end

	    (0..1).each do |rost|
		  	url_l = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,5,21,14,16,38,37,50,54,43,44,45&season=#{year}&month=13&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=#{rost}&age=0&filter=&players=0&page=1_50"
		  	url_r = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,5,21,14,16,38,37,50,54,43,44,45&season=#{year}&month=14&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=#{rost}&age=0&filter=&players=0&page=1_50"
		  	url_14 = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,5,21,14,16,38,37,50,61,43,44,45&season=#{year}&month=2&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=#{rost}&age=0&filter=&players=0&page=1_50"
		  	urls = [url_l, url_r, url_14]
		  	urls.each_with_index do |url, url_index|
		  	  doc = download_document(url)
		  	  index = { name: 1, ab: 2 + rost, sb: 3 + rost, bb: 4 + rost, so: 5 + rost, slg: 6 + rost, obp: 7 + rost, woba: 8 + rost,
		  	  	wrc: 9 + rost, ld: 10 + rost, gb: 11 + rost, fb: 12 + rost }

		  	  doc.css(".grid_line_regular").each_slice(13+rost) do |slice|
		  	  	name = slice[index[:name]].text
		  	  	fangraph_id = parse_fangraph_id(slice[index[:name]])
		  	  	player = Player.search(name, nil, fangraph_id)
	  	  	  unless player
	  	  	    puts "Player #{name} not found" 
	  	  	    next
	  	  	  end
		  	  	ab = slice[index[:ab]].text.to_i
		  	  	sb = slice[index[:sb]].text.to_i
		  	  	bb = slice[index[:bb]].text.to_i
		  	  	so = slice[index[:so]].text.to_i
		  	  	slg = (slice[index[:slg]].text.to_f*1000).to_i
		  	  	obp = (slice[index[:obp]].text.to_f*1000).to_i
		  	  	woba = (slice[index[:woba]].text.to_f*1000).to_i
		  	  	wrc = slice[index[:wrc]].text.to_i
		  	  	ld = slice[index[:ld]].text[0...-2].to_f
		  	  	gb = slice[index[:gb]].text[0...-2].to_f
		  	  	fb = slice[index[:fb]].text[0...-2].to_f
  	  	  	handedness = get_handedness(url_index)
  	  	  	batter = player.create_batter(season)
  	  	  	batter_stat = batter.stats.where(handedness: handedness).first
		  			batter_stat.update_attributes(ab: ab, sb: sb, bb: bb, so: so, slg: slg, obp: obp, woba: woba, wrc: wrc, ld: ld, gb: gb, fb: fb)
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