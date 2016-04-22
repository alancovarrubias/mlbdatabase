namespace :new do

  task daily: [:update_players]

  task hourly: [:update_weather, :ump, :bettinglines]

  task ten: [:matchups]

  task delete: :environment do
    game_day = GameDay.search(Time.now.tomorrow)
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
    include GameUpdate
    set_umpire
  end

  task :bettinglines => :environment do
    include GameUpdate
    closingline
  end

  task fix_bullpen: :environment do
    include NewBullpen
    fix_bullpen
  end

  task test: :environment do
  end
  
end