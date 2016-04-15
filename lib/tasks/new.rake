namespace :new do

  task delete: :environment do
    GameDay.search(Time.now).games.each do |game|
      game.lancers.destroy_all
      game.batters.destroy_all
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


  
end