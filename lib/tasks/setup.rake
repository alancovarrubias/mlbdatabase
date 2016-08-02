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
    Game.find(42939).lancers.where(starter: true).each do |lancer|
      season_lancer = Player.create_lancer(Season.find_by_year(2016))
      ld = season_lancer
      pitcher_stat = lancer.stats.where(handedness: "").first
      pitcher_stat.update_attributes(ld: ld, whip: whip, ip: ip, so: so, bb: bb, siera: siera)
    end
  end

end