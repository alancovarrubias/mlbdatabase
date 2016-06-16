module Update
  class OtherHour

    include NewShare

    def update(game)

      url = "http://www.baseball-reference.com/boxes/%s/%s.shtml" % [game.home_team.game_abbr, game.url]
      puts url

      doc = download_document(url)
      return unless doc
      elements = doc.css("#page_content .float_left")
      return if elements.size == 0
      hour = get_hour(elements[0].text)
      stadium = elements[1].text[2..-1]
      elements = doc.css(".stat_total td")[0..44]
      away_runs = elements[2].text.to_i
      home_runs = elements[24].text.to_i
      puts "GameID: #{game.id} Away Runs: #{away_runs} Home Runs: #{home_runs} Hour: #{hour} Stadium: #{stadium}"
      game.update(local_hour: hour, stadium: stadium, away_runs: away_runs, home_runs: home_runs)

    end

    private

      def get_hour(text)
        index = text.index(":")
        return 0 unless index
        hour = text[index-2..index-1].to_i
        hour += 12 if text[-2..-1] == "PM" && hour != 12
        return hour
      end

  end
end