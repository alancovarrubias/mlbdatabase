namespace :job do

  task create_season: :environment do
    Season.create(year: 2016)
  end
  
  task create_teams: :environment do
    Create::Teams.create
  end

  task create_players: :environment do
    players_creator = Create::Players.new
    Season.all.each do |season|
      Team.all.each do |team|
        players_creator.run(season, team)
        players_creator.fangraphs(team)
      end
    end
  end

  task update_batters: :environment do
    batters_updater = Update::Batters.new
    Season.all.each do |season|
      Team.all.each do |team|
        batters_updater.run(season, team)
      end
    end
  end

  task update_pitchers: :environment do
    pitchers_updater = Update::Pitchers.new
    Season.all.each do |season|
      Team.all.each do |team|
        pitchers_updater.run(season, team)
      end
    end
  end

  task create_matchups: :environment do
    game_creator = Create::Games.new
    bullpen_creator = Create::Bullpen.new
    time = Time.now
    game_creator.create(time)
    bullpen_creator.create(time)
  end

end