namespace :change do


  def find_player(name, identity)
    player = nil
  	if identity && identity != ""
      player = Player.find_by_identity(identity)
  	end
    unless player
      player = Player.find_by_name(name)
  	end
    return player
  end


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

  task bullpen_pitches_thrown: :environment do
    Game.all.each do |game|
      year = game.year
      game.pitchers.where(bullpen: true).each do |bullpen|
        player = find_player(bullpen.name, bullpen.alias)
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
          day = (Date.parse(time) - i).day
          month = game.month.to_i
          if day > game.day.to_i
            month -= 1
          end
          day = "%02d" % day
          month = "%02d" % month
          Game.where(year: year, month: month, day: day).each do |prev_game|
            prev_game.pitcher_stats.where(player_id: player.id).each do |pitcher_stat|
              if pitcher_stat.pitches == 0
                pitcher_stat.update_attributes(pitches: pitches)
              end
            end
          end
        end
      end
    end
  end


  task create_seasons_and_players: :environment do

    (2014..2016).each do |i|
      Season.create(year: i)
    end

  	Pitcher.all.each do |pitcher|
  	  player = find_player(pitcher.name, pitcher.alias)
      unless player
  	   player = Player.create(name: pitcher.name, identity: pitcher.alias, throwhand: pitcher.throwhand, bathand: pitcher.bathand)
       puts player.name + ' created'
      end
      fill_empty_attributes(player, pitcher)
  	end

  	Hitter.all.each do |hitter|
      player = find_player(hitter.name, hitter.alias)
      unless player
       player = Player.create(name: hitter.name, identity: hitter.alias, throwhand: hitter.throwhand, bathand: hitter.bathand)
       puts player.name + ' created'
      end
      fill_empty_attributes(player, hitter)
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



  task create_stats: :environment do

    season_2014 = Season.where(year: 2014).first
    season_2015 = Season.where(year: 2015).first

  	Pitcher.proto_pitchers.each do |pitcher|

  	  player = find_player(pitcher.name, pitcher.alias)
      unless player
        puts pitcher.name + " Not Found"
        next
      end
      # WHIP_previous SO_previous BB_previous ERA_previous missing


      PitcherStat.create(season_id: season_2014.id, player_id: player.id, handedness: "L", range: "Full Season", ip: pitcher.IP_previous_L, 
       fip: pitcher.FIP_previous, xfip: pitcher.xFIP_previous_L, kbb: pitcher.KBB_previous_L,
        woba: pitcher.wOBA_previous_L, ops: pitcher.OPS_previous_L, fb: pitcher.FB_previous_L, gb: pitcher.GB_previous_L,
        )

      PitcherStat.create(season_id: season_2014.id, player_id: player.id, handedness: "R", range: "Full Season", ip: pitcher.IP_previous_R, 
       fip: pitcher.FIP_previous, xfip: pitcher.xFIP_previous_R, kbb: pitcher.KBB_previous_R,
        woba: pitcher.wOBA_previous_R, ops: pitcher.OPS_previous_R, fb: pitcher.FB_previous_R, gb: pitcher.GB_previous_R,
        )

      PitcherStat.create(season_id: season_2015.id, player_id: player.id, handedness: "L", range: "Full Season", whip: pitcher.WHIP_L, ip: pitcher.IP_L, 
        so: pitcher.SO_L, bb: pitcher.BB_L, fip: pitcher.FIP, xfip: pitcher.xFIP_L, kbb: pitcher.KBB_L,
        woba: pitcher.wOBA_L, ops: pitcher.OPS_L, era: pitcher.ERA_L, fb: pitcher.FB_L, gb: pitcher.GB_L,
        ld: pitcher.LD_L)

      PitcherStat.create(season_id: season_2015.id, player_id: player.id, handedness: "R", range: "Full Season", whip: pitcher.WHIP_R, ip: pitcher.IP_R, 
        so: pitcher.SO_R, bb: pitcher.BB_R, fip: pitcher.FIP, xfip: pitcher.xFIP_R, kbb: pitcher.KBB_R,
        woba: pitcher.wOBA_R, ops: pitcher.OPS_R, era: pitcher.ERA_R, fb: pitcher.FB_R, gb: pitcher.GB_R,
        ld: pitcher.LD_R)

      
  	end

  	Hitter.proto_hitters.each do |hitter|

      player = find_player(hitter.name, hitter.alias)
      unless player
        puts hitter.name + " Not Found"
        next
      end

      BatterStat.create(season_id: season_2014.id, player_id: player.id, handedness: "L", range: "Full Season", woba: hitter.wOBA_previous_L, ops: hitter.OPS_previous_L, 
        ab: hitter.AB_previous_L, so: hitter.SO_previous_L, bb: hitter.BB_previous_L, sb: hitter.SB_previous_L, fb: hitter.FB_previous_L, gb: hitter.GB_previous_L,
        ld: hitter.LD_previous_L, wrc: hitter.wRC_previous_L, obp: hitter.OBP_previous_L, slg: hitter.SLG_previous_L)

      BatterStat.create(season_id: season_2014.id, player_id: player.id, handedness: "R", range: "Full Season", woba: hitter.wOBA_previous_R, ops: hitter.OPS_previous_R, 
        ab: hitter.AB_previous_R, so: hitter.SO_previous_R, bb: hitter.BB_previous_R, sb: hitter.SB_previous_R, fb: hitter.FB_previous_R, gb: hitter.GB_previous_R,
        ld: hitter.LD_previous_R, wrc: hitter.wRC_previous_R, obp: hitter.OBP_previous_R, slg: hitter.SLG_previous_R)

      BatterStat.create(season_id: season_2015.id, player_id: player.id, handedness: "L", range: "Full Season", woba: hitter.wOBA_L, ops: hitter.OPS_L, 
        ab: hitter.AB_L, so: hitter.SO_L, bb: hitter.BB_L, sb: hitter.SB_L, fb: hitter.FB_L, gb: hitter.GB_L,
        ld: hitter.LD_L, wrc: hitter.wRC_L, obp: hitter.OBP_L, slg: hitter.SLG_L)

      BatterStat.create(season_id: season_2015.id, player_id: player.id, handedness: "R", range: "Full Season", woba: hitter.wOBA_R, ops: hitter.OPS_R, 
        ab: hitter.AB_R, so: hitter.SO_R, bb: hitter.BB_R, sb: hitter.SB_R, fb: hitter.FB_R, gb: hitter.GB_R,
        ld: hitter.LD_R, wrc: hitter.wRC_R, obp: hitter.OBP_R, slg: hitter.SLG_R)
      

  	end

  end

  task create_game_stats: :environment do
    Game.all.each do |game|

      season = Season.where(year: game.year.to_i).first

      Weather.create(game_id: game.id, station: "Forecast", hour: 1, wind: game.wind_1, humidity: game.humidity_1, pressure: game.pressure_1, temp: game.temperature_1, rain: game.precipitation_1)
      Weather.create(game_id: game.id, station: "Forecast", hour: 2, wind: game.wind_2, humidity: game.humidity_2, pressure: game.pressure_2, temp: game.temperature_2, rain: game.precipitation_2)
      Weather.create(game_id: game.id, station: "Forecast", hour: 3, wind: game.wind_3, humidity: game.humidity_3, pressure: game.pressure_3, temp: game.temperature_3, rain: game.precipitation_3)
      Weather.create(game_id: game.id, station: "Actual", hour: 1, wind: game.wind_1_value, humidity: game.humidity_1_value, pressure: game.pressure_1_value, temp: game.temperature_1_value, rain: game.precipitation_1_value)
      Weather.create(game_id: game.id, station: "Actual", hour: 2, wind: game.wind_2_value, humidity: game.humidity_2_value, pressure: game.pressure_2_value, temp: game.temperature_2_value, rain: game.precipitation_2_value)
      Weather.create(game_id: game.id, station: "Actual", hour: 3, wind: game.wind_3_value, humidity: game.humidity_3_value, pressure: game.pressure_3_value, temp: game.temperature_3_value, rain: game.precipitation_3_value)


      game.hitters.each do |hitter|

        player = find_player(hitter.name, hitter.alias)
        unless player
          puts hitter.name + " Pitcher Not Found"
          next
        end

        # stat = BatterStat.create(season_id: season.id, player_id: player.id, game_id: game.id, team_id: hitter.team_id, handedness: "L", range: "Game Season", woba: hitter.wOBA_L, ops: hitter.OPS_L, 
        # ab: hitter.AB_L, so: hitter.SO_L, bb: hitter.BB_L, sb: hitter.SB_L, fb: hitter.FB_L, gb: hitter.GB_L, ld: hitter.LD_L, wrc: hitter.wRC_L, obp: hitter.OBP_L, slg: hitter.SLG_L)

        # puts stat.player.name

        # stat = BatterStat.create(season_id: season.id, player_id: player.id, game_id: game.id, team_id: hitter.team_id, handedness: "R", range: "Game Season", woba: hitter.wOBA_R, ops: hitter.OPS_R, 
        # ab: hitter.AB_R, so: hitter.SO_R, bb: hitter.BB_R, sb: hitter.SB_R, fb: hitter.FB_R, gb: hitter.GB_R, ld: hitter.LD_R, wrc: hitter.wRC_R, obp: hitter.OBP_R, slg: hitter.SLG_R)

        stat = BatterStat.create(season_id: season.id, player_id: player.id, game_id: game.id, team_id: hitter.team_id, handedness: "", range: "14 Days", woba: hitter.wOBA_14, ops: hitter.OPS_14, 
        ab: hitter.AB_14, so: hitter.SO_14, bb: hitter.BB_14, sb: hitter.SB_14, fb: hitter.FB_14, gb: hitter.GB_14, ld: hitter.LD_14, wrc: hitter.wRC_14, obp: hitter.OBP_14, slg: hitter.SLG_14)

        puts stat.player.name

      end


      game.pitchers.each do |pitcher|

        player = find_player(pitcher.name, pitcher.alias)
        unless player
          puts pitcher.name + " Pitcher Not Found"
          next
        end

       # stat = PitcherStat.create(season_id: season.id, player_id: player.id, game_id: game.id, team_id: pitcher.team_id, handedness: "L", range: "Game Season", starter: pitcher.starter, bullpen: pitcher.bullpen,
       #  whip: pitcher.WHIP_L, ip: pitcher.IP_L, so: pitcher.SO_L, bb: pitcher.BB_L, fip: pitcher.FIP, xfip: pitcher.xFIP_L, kbb: pitcher.KBB_L,
       #  woba: pitcher.wOBA_L, ops: pitcher.OPS_L, era: pitcher.ERA_L, fb: pitcher.FB_L, gb: pitcher.GB_L, ld: pitcher.LD_L)

       # puts stat.player.name

       #  stat = PitcherStat.create(season_id: season.id, player_id: player.id, game_id: game.id, team_id: pitcher.team_id, handedness: "R", range: "Game Season", starter: pitcher.starter, bullpen: pitcher.bullpen,
       #    whip: pitcher.WHIP_R, ip: pitcher.IP_R, so: pitcher.SO_R, bb: pitcher.BB_R, fip: pitcher.FIP, xfip: pitcher.xFIP_L, kbb: pitcher.KBB_R,
       #    woba: pitcher.wOBA_R, ops: pitcher.OPS_R, era: pitcher.ERA_R, fb: pitcher.FB_R, gb: pitcher.GB_R, ld: pitcher.LD_R)

       #  puts stat.player.name

        stat = PitcherStat.create(season_id: season.id, player_id: player.id, game_id: game.id, team_id: pitcher.team_id, handedness: "R", range: "30 Days", starter: pitcher.starter, bullpen: pitcher.bullpen,
          ld: pitcher.LD_30, whip: pitcher.WHIP_30, ip: pitcher.SO_30, bb: pitcher.BB_30)

        puts stat.player.name

      end
    end
  end



end