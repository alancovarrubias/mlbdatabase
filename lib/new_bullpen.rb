module NewBullpen

  include NewShare

  def create_bullpen(game_day)
    games = game_day.games
    Lancer.bullpen.each do |lancer|
      player = lancer.player
      team = player.team
      if team
        games.where("away_team_id = #{team.id} OR home_team_id = #{team.id}").each do |game|
          lancer = player.create_lancer(lancer.season, team, game)
          lancer.update_attributes(bullpen: true)
        end
      end
    end
  end

  def get_pitches(text)
    if text == "N/G"
  	  return 0
  	else
  	  return text.to_i
  	end
  end

  def update_bullpen_pitches(player, one, two, three, time)
    (1..3).each do |n|
      game_day = GameDay.search(time)
      time = time.yesterday
	    case n
      when 1
        pitches = one
      when 2
        pitches = two
      when 3
        pitches = three
      end
      lancers = player.game_day_lancers(game_day)
      lancers.each do |lancer|
        lancer.update(pitches: pitches)
      end
    end
  end

  def set_bullpen(time)
    @bullpen_teams = [1, 2, 3, 4, 12, 13, 17, 21, 22, 23, 26, 27, 28, 29, 30, 5, 6, 7, 8, 9, 10, 11, 14, 15, 16, 18, 19, 20, 24, 25]
    url = "http://www.baseballpress.com/bullpenusage/%d-%02d-%02d" % [time.year, time.month, time.day]
    puts url
    doc = download_document(url)

    Lancer.bullpen.update_all(bullpen: false)
  	player = nil
  	var = one = two = three = 0
    team_index = -1
    season = Season.find_by_year(time.year)
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
  		  update_bullpen_pitches(player, one, two, three, time)
  		  var = 0
	    end
  	  # Elements with two children contain the pitcher information
  	  if element.children.size == 2
  	  	identity, fangraph_id, name, handedness = pitcher_info(element)
  	  	player = Player.search(name, identity, fangraph_id)
        unless player
          player = Player.create(name: name, identity: identity, throwhand: handedness)
        end
        player.update(team_id: @bullpen_teams[team_index])
        lancer = player.create_lancer(season)
        lancer.update(bullpen: true)
  		  var = 1
  	  end
  	end
    game_day = GameDay.search(time)
    create_bullpen(game_day)
  end

  def fix_bullpen

    GameDay.all.each do |game_day|
      
      url = "http://www.baseballpress.com/bullpenusage/%d-%02d-%02d" % [game_day.year, game_day.month, game_day.day]
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
          lancers = player.game_day_lancers(game_day)
          lancers.each do |lancer|
            puts "#{player.name} #{lancer.game.url} pitches #{one}"
            lancer.update(pitches: one)
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