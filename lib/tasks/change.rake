namespace :change do


  def fill_empty_attributes(player, pitter)
      if player.identity == "" && pitter.alias && pitter.alias != ""
        player.update_attributes(identity: pitter.alias)
      end
      if player.fangraph_id == nil && pitter.fangraph_id && pitter.fangraph_id != 0
        player.update_attributes(fangraph_id: pitter.fangraph_id)
      end
      if player.throwhand == "" && pitter.throwhand && pitter.throwhand != ""
        player.update_attributes(throwhand: pitter.throwhand)
      end
      if player.bathand == "" && pitter.bathand && pitter.bathand != ""
        player.update_attributes(bathand: pitter.bathand)
      end
  end

  def get_correct_pitches(i, pitcher)
    pitches = 0
    case i
    when 1
      pitches = pitcher.one
    when 2
      pitches = pitcher.two
    when 3
      pitches = pitcher.three
    when 4
      pitches = pitcher.four
    when 5
      pitches = pitcher.five
    end
    return pitches
  end


  task create_players: :environment do

  	Pitcher.where(game_id: nil).each do |pitcher|
  	  player = Player.search(pitcher.name, pitcher.alias)
      unless player
        player = Player.create(name: pitcher.name, team_id: pitcher.team_id, identity: pitcher.alias, throwhand: pitcher.throwhand, bathand: pitcher.bathand)
        puts player.name + ' created'
      end
      if player
        fill_empty_attributes(player, pitcher)
      end
  	end

  	Hitter.where(game_id: nil).each do |hitter|
      player = Player.search(hitter.name, hitter.alias)
      unless player
        if hitter.alias
          player = Player.create(name: hitter.name, team_id: hitter.team_id, identity: hitter.alias, throwhand: hitter.throwhand, bathand: hitter.bathand)
          puts player.name + ' created'
        end
      end
      if player
        fill_empty_attributes(player, hitter)
      end
  	end

  end


  task create_game_days: :environment do
  	(2014..2016).each do |year|
      season = Season.where(year: year).first
  	  (1..12).each do |month|
  	  	(1..31).each do |day|
  	  	  if Game.where(year: "%d" % year, month: "%02d" % month, day: "%02d" % day).size > 0
  	  	  	GameDay.create(season_id: season.id, year: year, month: month, day: day)
  	  	  end
  	  	end
  	  end
  	end

    GameDay.all.each do |game_day|
      Game.where(year: "%d" % game_day.year, month: "%02d" % game_day.month, day: "%02d" % game_day.day).each do |game|
        game.update_attributes(game_day_id: game_day.id)
      end
    end
  end


  task create_game_stats: :environment do

    Game.all.each do |game|

      season = Season.find_by_year(game.year.to_i)

      Weather.create(game_id: game.id, station: "Forecast", hour: 1, wind: game.wind_1, humidity: game.humidity_1, pressure: game.pressure_1, temp: game.temperature_1, rain: game.precipitation_1)
      Weather.create(game_id: game.id, station: "Forecast", hour: 2, wind: game.wind_2, humidity: game.humidity_2, pressure: game.pressure_2, temp: game.temperature_2, rain: game.precipitation_2)
      Weather.create(game_id: game.id, station: "Forecast", hour: 3, wind: game.wind_3, humidity: game.humidity_3, pressure: game.pressure_3, temp: game.temperature_3, rain: game.precipitation_3)
      Weather.create(game_id: game.id, station: "Actual",   hour: 1, wind: game.wind_1_value, humidity: game.humidity_1_value, pressure: game.pressure_1_value, temp: game.temperature_1_value, rain: game.precipitation_1_value)
      Weather.create(game_id: game.id, station: "Actual",   hour: 2, wind: game.wind_2_value, humidity: game.humidity_2_value, pressure: game.pressure_2_value, temp: game.temperature_2_value, rain: game.precipitation_2_value)
      Weather.create(game_id: game.id, station: "Actual",   hour: 3, wind: game.wind_3_value, humidity: game.humidity_3_value, pressure: game.pressure_3_value, temp: game.temperature_3_value, rain: game.precipitation_3_value)


      game.hitters.each do |hitter|

        player = Player.search(hitter.name, hitter.alias)
        unless player
          puts hitter.name + " Batter Not Found"
          next
        end

        batter = player.create_batter(season, hitter.team, game)

        batter.update_attributes(starter: hitter.starter, lineup: hitter.lineup)

        batter.stats("L").update_attributes(woba: hitter.wOBA_L, ops: hitter.OPS_L, 
        ab: hitter.AB_L, so: hitter.SO_L, bb: hitter.BB_L, sb: hitter.SB_L, fb: hitter.FB_L, gb: hitter.GB_L, ld: hitter.LD_L, wrc: hitter.wRC_L, obp: hitter.OBP_L, slg: hitter.SLG_L)

        batter.stats("R").update_attributes(woba: hitter.wOBA_R, ops: hitter.OPS_R, 
        ab: hitter.AB_R, so: hitter.SO_R, bb: hitter.BB_R, sb: hitter.SB_R, fb: hitter.FB_R, gb: hitter.GB_R, ld: hitter.LD_R, wrc: hitter.wRC_R, obp: hitter.OBP_R, slg: hitter.SLG_R)

        batter.stats("").update_attributes(woba: hitter.wOBA_14, ops: hitter.OPS_14, 
        ab: hitter.AB_14, so: hitter.SO_14, bb: hitter.BB_14, sb: hitter.SB_14, fb: hitter.FB_14, gb: hitter.GB_14, ld: hitter.LD_14, wrc: hitter.wRC_14, obp: hitter.OBP_14, slg: hitter.SLG_14)

      end


      game.pitchers.each do |pitcher|

        player = Player.search(pitcher.name, pitcher.alias)
        unless player
          puts pitcher.name + " Pitcher Not Found"
          next
        end

        lancer = player.create_lancer(season, pitcher.team, game)

        lancer.update_attributes(starter: pitcher.starter, bullpen: pitcher.bullpen)

        lancer.stats("L").update_attributes(whip: pitcher.WHIP_L, ip: pitcher.IP_L, so: pitcher.SO_L, bb: pitcher.BB_L, fip: pitcher.FIP, xfip: pitcher.xFIP_L, kbb: pitcher.KBB_L,
          woba: pitcher.wOBA_L, ops: pitcher.OPS_L, era: pitcher.ERA_L, fb: pitcher.FB_L, gb: pitcher.GB_L, ld: pitcher.LD_L)

        lancer.stats("R").update_attributes(whip: pitcher.WHIP_R, ip: pitcher.IP_R, so: pitcher.SO_R, bb: pitcher.BB_R, fip: pitcher.FIP, xfip: pitcher.xFIP_L, kbb: pitcher.KBB_R,
          woba: pitcher.wOBA_R, ops: pitcher.OPS_R, era: pitcher.ERA_R, fb: pitcher.FB_R, gb: pitcher.GB_R, ld: pitcher.LD_R)

        lancer.stats("").update_attributes(ld: pitcher.LD_30, whip: pitcher.WHIP_30, ip: pitcher.SO_30, bb: pitcher.BB_30)

      end
    end
  end

  task bullpen_pitches_thrown: :environment do
    Game.all.each do |game|
      year = game.year
      game.pitchers.where(bullpen: true).each do |bullpen|
        player = Player.search(bullpen.name, bullpen.alias)
        unless player
          puts bullpen.name + " not found"
          next
        end
        time = game.year + "-" + game.month + "-" + game.day
        (1..5).each do |i|
          pitches = get_correct_pitches(i, bullpen)
          if pitches == 0
            next
          end
          date = Date.parse(time) - i
          day = date.day
          month = date.month
          day = "%02d" % day
          month = "%02d" % month
          games = Game.where(year: year, month: month, day: day)
          game_ids = games.map { |game| game.id }
          Lancer.where(game_id: game_ids, player_id: player.id).each do |lancer|
            if lancer.pitches == 0
              puts pitches
              lancer.update_attributes(pitches: pitches)
            end
          end
        end
      end
    end
  end


  task fix: :environment do
    GameDay.search(Time.now.yesterday).games.each do |game|
      if weather.temp.size == 0
        weather.destroy
      end
    end

    GameDay.search(Time.now).games.each do |game|
      if weather.temp.size == 0
        weather.destroy
      end
    end
  end


end