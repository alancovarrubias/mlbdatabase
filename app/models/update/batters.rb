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
	        end
	      end
	    end

	  	url_l = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,5,21,14,16,38,37,50,54,43,44,45&season=#{year}&month=13&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=0&age=0&filter=&players=0&page=1_50"
	  	url_r = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,5,21,14,16,38,37,50,54,43,44,45&season=#{year}&month=14&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=0&age=0&filter=&players=0&page=1_50"
	  	url_14 = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,5,21,14,16,38,37,50,61,43,44,45&season=#{year}&month=2&season1=#{year}&ind=0&team=#{team.fangraph_id}&rost=0&age=0&filter=&players=0&page=1_50"
	  	urls = [url_l, url_r, url_14]
	  	urls.each_with_index do |url, url_index|
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