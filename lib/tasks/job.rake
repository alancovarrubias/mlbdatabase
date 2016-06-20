namespace :job do

  task daily: [:create_players, :update_batters, :update_pitchers, :update_hour_stadium_runs]

  task hourly: [:update_weather, :update_forecast, :update_games]

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
    Season.all.each { |season| season.create_players }
  end

  task update_batters: :environment do
    Season.all.each { |season| season.update_batters }
  end

  task update_pitchers: :environment do
    Season.all.map { |season| season.update_pitchers }
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

  task fix_weather: :environment do
    GameDay.all.each do |game_day|
      game_day.update_weather
    end
  end

  task delete_games: :environment do
    [GameDay.today, GameDay.tomorrow].each { |game_day| game_day.delete_games }
  end

  task fix_pitcher_box_score: :environment do
    GameDay.all.each { |game_day| game_day.pitcher_box_score }
  end

  task update_local_hour: :environment do
    Season.where("year >= 2010").each { |season| season.game_days.each{ |game_day| game_day.update_local_hour } }
  end

  task update_hour_stadium_runs: :environment do
    Game.where(stadium: "").each do |game|
      game.update_hour_stadium_runs
    end
  end

  task fix: :environment do
    GameDay.yesterday.update_weather
    GameDay.yesterday.update_games
  end

  task test_weather: :environment do
    GameDay.find(5844).update_weather
  end

end