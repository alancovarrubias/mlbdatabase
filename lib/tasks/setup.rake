namespace :setup do



	task test: :environment do
    require 'nokogiri'
    require 'open-uri'

    url = "http://www.baseballpress.com/lineups"
    doc = Nokogiri::HTML(open(url))
    doc.css(".players div, .team-name+ div, .team-name, .game-time").each do |element|
      puts element.text
    end
    
  end

  task whoo: :environment do
    [GameDay.yesterday, GameDay.today, GameDay.tomorrow].each do |game_day|
      season = game_day.season
      game_day.games.each do |game|
        game.lancers.each do |lancer|
          season_lancer = lancer.player.create_lancer(season)
          lancer.update(h: season_lancer.h)
        end
      end
    end
  end

end