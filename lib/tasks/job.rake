namespace :job do

  task daily: [:create_players, :update_batters, :update_pitchers, :update_hour_stadium_runs]

  task hourly: [:update_weather, :update_forecast, :update_games, :pitcher_box_score, :test_bullpen]

  task ten: [:create_matchups]

  task create_season: :environment do
    Season.create_seasons
  end
  
  task create_teams: :environment do
    Team.create_teams
  end

  task create_games: :environment do
    Season.all.each { |season| season.create_games }
  end

  task create_players: :environment do
    Season.where("year > 2014").each { |season| season.create_players }
  end

  task update_batters: :environment do
    Season.where("year > 2014").order("year DESC").each { |season| season.update_batters }
  end

  task update_pitchers: :environment do
    Season.where("year > 2014").map { |season| season.update_pitchers }
  end

  task create_matchups: :environment do
    [GameDay.yesterday, GameDay.today, GameDay.tomorrow].each { |game_day| game_day.create_matchups }
  end

  task update_games: :environment do
    GameDay.today.update_games
  end

  task update_weather: :environment do
    GameDay.today.update_weather
  end

  task update_forecast: :environment do
    [GameDay.today, GameDay.tomorrow].each { |game_day| game_day.update_forecast }
  end

  task pitcher_box_score: :environment do
    GameDay.yesterday.pitcher_box_score
  end

  task delete_games: :environment do
    GameDay.today.delete_games
  end

  task update_local_hour: :environment do
    Season.all.each { |season| season.game_days.each{ |game_day| game_day.update_local_hour } }
  end

  task update_hour_stadium_runs: :environment do
    Game.where(stadium: "").each do |game|
      game.update_hour_stadium_runs
    end
  end

  task fix_weather: :environment do
    GameDay.all.each do |game_day|
      game_day.update_weather
    end
  end

  task test_bullpen: :environment do
    Test::Bullpen.new.run
  end

  task fix_game_lancers: :environment do
    Game.all.each do |game|
      away_id = game.away_team_id
      home_id = game.home_team_id
      game.lancers.where.not("team_id = #{away_id} OR team_id = #{home_id}").destroy_all
    end
  end

end
