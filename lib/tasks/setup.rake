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

end