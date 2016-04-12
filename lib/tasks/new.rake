namespace :new do

  task update_players: :environment do
  	include PlayerUpdate

    Season.last.each do |season|
      Team.all.each do |team|
        create_players(season, team)
      end
    end

  	Team.all.each do |team|
  	  fangraphs(team)
  	end

  	Season.all.each do |season|
  	  Team.all.each do |team|
  	  	update_batters(season, team)
  	    update_pitchers(season, team)
  	  end
  	end
  end

  task matchups: :environment do
    include NewMatchup
    include NewBullpen
    set_bullpen
    set_matchups(Time.now)
    set_matchups(Time.now.tomorrow)
  end

  task update_weather: :environment do
  	include WeatherUpdate

  	time = Time.now
  	GameDay.search(time).games.each do |game|
  	  create_weathers(game)
	    update_pressure_forecast(game)
	    update_forecast(game, time)
	    update_weather(game)
	  end

	  time = Time.now.tomorrow
	  GameDay.search(time).games.each do |game|
	    create_weathers(game)
  	  update_pressure_forecast(game)
	    update_forecast(game, time)
	  end

  end

  task test: :environment do
    include NewShare
    def parse_identity(element)
      href = element.child.child['href']
      if href == nil
      href = element.child['href']
      end
      return href[11..href.index(".")-1]
    end
    url = "http://www.baseball-reference.com/teams/NYY/2016.shtml"
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
          player.season_batter_stats(season).each do |stat|
            if stat.handedness.size > 0
              stat.update_attributes(ops: ops)
            end
          end
        else
          puts name + " not found"
        end
      end
    end
  end


  
end