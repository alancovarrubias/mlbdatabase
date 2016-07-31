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
    year = 2016
    player = Player.find_by_name("Carlos Martinez")
    url = "http://www.baseball-reference.com/teams/STL/2016-roster.shtml"
    doc = Nokogiri::HTML(open(url))
    doc.css("#appearances td").each_slice(28) do |slice|
      puts slice[0]
    end
    # puts url
  end

end