namespace :new do

  task :daily => [:update_players]

  task :hourly => [:update_weather, :ump, :closingline]

  task :ten => [:matchups]

  task delete: :environment do
    game_day = GameDay.search(Time.now)
    game_day.games.each do |game|
      game.destroy
    end
  end

  task update_players: :environment do
  	include PlayerUpdate

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

  task ump: :environment do
    include Matchup
    url = "http://www.statfox.com/mlb/umpiremain.asp"
    doc = Nokogiri::HTML(open(url))
    set_umpire(doc)
  end

  task :closingline => :environment do

    include Share
    hour, day, month, year = find_date(Time.now)
    game_day = GameDay.search(Time.now)
    today_games = game_day.games
    size = today_games.size
    date_url = "?date=#{year}#{month}#{day}"
    url = "http://www.sportsbookreview.com/betting-odds/mlb-baseball/" + date_url
    puts url
    doc = Nokogiri::HTML(open(url))
    game_array = Array.new
    doc.css(".team-name a").each_with_index do |stat, index|
      if index == size*2
        break
      end
      if index%2 == 1
        abbr = stat.child.text[0...-3].to_s
        case abbr
        when "TB"
          abbr = "TBR"
        when "SF"
          abbr = "SFG"
        when "SD"
          abbr = "SDP"
        when "CWS"
          abbr = "CHW"
        when "KC"
          abbr = "KCR"
        when "WSH"
          abbr = "WSN"
        end
        team = Team.find_by_abbr(abbr)
        unless team
          game_array << nil
          next
        end
        games = today_games.where(:home_team_id => team.id)
        if games.size == 2
          if game_array.include?(games.first)
            game_array << games.second
          else
            game_array << games.first
          end
        elsif games.size == 1
          game_array << games.first
        else
          game_array << nil
        end   
      end
    end

    away_money_line = Array.new
    home_money_line = Array.new
    doc.css(".eventLine-consensus+ .eventLine-book b").each_with_index do |stat, index|
      if index == size*2
        break
      end
      if index%2 == 0
        away_money_line << stat.text
      else
        home_money_line << stat.text
      end
    end

    away_totals = Array.new
    home_totals = Array.new
    url = "http://www.sportsbookreview.com/betting-odds/mlb-baseball/totals/" + date_url
    doc = Nokogiri::HTML(open(url))
    doc.css(".eventLine-consensus+ .eventLine-book b").each_with_index do |stat, index|
      if index == size*2
        break
      end
      if index%2 == 0
        away_totals << stat.text
      else
        home_totals << stat.text
      end
    end

    (0...size).each do |i|
      game = game_array[i]
      if game
        puts game.url
        game.update_attributes(:away_money_line => away_money_line[i], :home_money_line => home_money_line[i], :away_total => away_totals[i], :home_total => home_totals[i])
      end
    end
  end


  task fix_bullpen_pitches: :environment do
    include NewShare
    GameDay.all.each do |game_day|

      year = game_day.year
      month = "%02d" % game_day.month
      day = "%02d" % game_day.day
      url = "http://www.baseballpress.com/bullpenusage/#{year}-#{month}-#{day}"
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

  task test: :environment do
    (1..5).each_with_index do |i, index|
      puts "#{i} #{index}"
    end
  end


  
end