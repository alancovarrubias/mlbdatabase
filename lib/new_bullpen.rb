module NewBullpen

  include NewShare

  def get_pitches(text)
    if text == "N/G"
	  return 0
	else
	  return text.to_i
	end
  end

  def reset_bullpen
  	Player.bullpen.update_all(bullpen: false)
  end

  def update_bullpen_pitches(player, one, two, three)
    time = Time.now
    (1..3).each do |n|
      time = time.yesterday
      game_day = GameDay.search(time)
      games = game_day.games
      if games.empty?
      	next
      end
      game_ids = games.map { |game| game.id }
	  case n
      when 1
        pitches = one
      when 2
        pitches = two
      when 3
        pitches = three
      end
      if pitches == 0
      	next
      end
      PitcherStat.where(player_id: player.id, game_id: game_ids).each do |pitcher_stat|
      	pitcher_stat.update_attributes(pitches: pitches)
      end
    end
  end

  def set_bullpen
    url = "http://www.baseballpress.com/bullpenusage"
    doc = download_document(url)

    reset_bullpen
	player = nil
	var = one = two = three = 0
	doc.css(".league td").each do |element|

	  text = element.text
	  case var
	  when 1
	    one = get_pitches(text)
		var += 1
	  when 2
		two = get_pitches(text)
		var += 1
	  when 3
		three = get_pitches(text)
		update_bullpen_pitches(player, one, two, three)
		var = 0
	  end

	  # Elements with two children contain the pitcher information
	  if element.children.size == 2
	  	identity, fangraph_id, name, handedness = pitcher_info(element)
	  	player = Player.search(name, identity, fangraph_id)
	  	if player
	  	  player.update_attributes(bullpen: true)
	  	else
	  	  puts "Bullpen pitcher " + name + " not found"
	  	end
		var = 1
	  end
	end
  end

end