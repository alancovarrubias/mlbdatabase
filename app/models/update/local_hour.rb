module Update
  class LocalHour

    include NewShare

    def update(game)
      url = "http://www.baseball-reference.com/previews/#{game.game_day.date.year}/#{game.url}.shtml"
      doc = Nokogiri::HTML(open(url))
      puts url
      doc.css(".bold_text+ .float_left:nth-child(4)").each do |stat|
        text = stat.text
        hour = text[0...text.index(":")].to_i
        unless hour > 9
          hour += 12
        end
        game.update(local_hour: hour)
      end
    end

  end
end