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
    Lancer.where(game_id: nil, bullpen: true).update_all(bullpen: false)
  end

  def update_bullpen_pitches(player, one, two, three)
    time = Time.now.tomorrow
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
      Lancer.where(player_id: player.id, game_id: game_ids).each do |lancer|
      	lancer.update_attributes(pitches: pitches)
      end
    end
  end

  def set_bullpen
    @bullpen_teams = [1, 2, 3, 4, 12, 13, 17, 21, 22, 23, 26, 27, 28, 29, 30, 5, 6, 7, 8, 9, 10, 11, 14, 15, 16, 18, 19, 20, 24, 25]
    time = Time.now
    year = time.year
    month = "%02d" % time.month
    day = "%02d" % time.day
    url = "http://www.baseballpress.com/bullpenusage/#{year}-#{month}-#{day}"
    doc = download_document(url)

    reset_bullpen
  	player = nil
  	var = one = two = three = 0
    team_index = -1
    season = Season.find_by_year(Time.now.year)
  	doc.css(".league td").each do |element|
  	  text = element.text

      if text == "Pitcher"
        team_index += 1
      end

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
        unless player
          player = Player.create(name: name, identity: identity, throwhand: handedness)
        end
        player.update_attributes(team_id: @bullpen_teams[team_index])
        lancer = player.create_lancer(season)
        lancer.update_attributes(bullpen: true)
  		  var = 1
  	  end
  	end
  end

  def fix_bullpen

    GameDay.all.each do |game_day|
      
      url = "http://www.baseballpress.com/bullpenusage/%d-%02d-%02d" % [game_day.year, game_day.month, game_day.day]
      puts url
      doc = download_document(url)
      player = nil
      var = one = 0
      doc.css(".league td").each do |element|

        text = element.text

        case var
        when 1
          var = 0
          if text == "N/G"
            one = 0
          else
            one = text.to_i
          end
          games = game_day.games
          if games.empty?
            next
          end
          game_ids = games.map { |game| game.id }
          Lancer.where(player_id: player.id, game_id: game_ids).each do |lancer|
            puts "#{player.name} #{lancer.game.url} pitches #{one}"
            lancer.update_attributes(pitches: one)
          end
        end

        if element.children.size == 2
          identity, fangraph_id, name, handedness = pitcher_info(element)
          player = Player.search(name, identity, fangraph_id)
          var = 1
        end

      end
    end
    
  end



end