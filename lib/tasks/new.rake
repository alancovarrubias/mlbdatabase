namespace :new do

  task daily: [:update_players, :pitcher_box]

  task hourly: [:update_weather, :update_game]

  task ten: [:matchups]

  task delete: :environment do
    # GameDay.search(Time.now).games.destroy_all
    GameDay.search(Time.now.tomorrow).games.destroy_all
  end

  task update_players: :environment do
  	include StatUpdate

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
    time = Time.now
    set_matchups(time)
    set_bullpen(time)
    time = time.tomorrow
    set_matchups(time)
    set_bullpen(time)
  end

  task update_weather: :environment do
    
  	time = Time.now
  	GameDay.search(time).games.each do |game|
      game.create_weather
      game.update_weather
      game.update_forecast
	  end

    time = time.tomorrow
	  GameDay.search(time).games.each do |game|
      game.create_weather
      game.update_weather
      game.update_forecast
	  end

  end

  task update_game: :environment do
    include GameUpdate
    set_umpire
    closingline
  end

  task pitcher_box: :environment do
    include PlayerUpdate
    game_day = GameDay.search(Time.now.yesterday)
    game_pitchers(game_day)
  end

  task fix_bullpen: :environment do
    include NewBullpen
    fix_bullpen
  end

  task fix_pitcher_past: :environment do
    include PlayerUpdate
    today_day = GameDay.search(Time.now)
    tomorrow_day = GameDay.search(Time.now.tomorrow)
    GameDay.all.each do |game_day|
      if game_day.is_preseason? || game_day == today_day || game_day == tomorrow_day
        next
      end
      game_pitchers(game_day)
    end
  end

  task fix_weather: :environment do
    include WeatherUpdate
    Game.all.each do |game|
      unless game.true_weather.dew == ""
        next
      end
      update_true_weather(game)
    end
  end

  task fix: :environment do
    game_day = GameDay.find(270)
    Update::Pitchers.new.box_scores(game_day)
  end

  
end