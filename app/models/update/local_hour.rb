module Update
  class LocalHour

    include NewShare

    def update(game_day)

      teams = game_day.season.teams
      date = game_day.date
      @games = game_day.games
      @home_teams = Array.new

      url = "http://www.baseballpress.com/lineups/%d-%02d-%02d" % [date.year, date.month, date.day]
      puts url

      doc = download_document(url)
      doc.css(".team-name, .game-time").each_slice(3) do |slice|
        hour = get_hour(slice[0].text)
        away_team = teams.find_by_name(slice[1].text)
        home_team = teams.find_by_name(slice[2].text)
        next unless home_team && hour
        game = get_game(hour)
        game.update(local_hour: hour) if game
      end

    end

    private

      def get_hour(text)
        if index = text.index(":")
          hour = text[0...text.index(":")].to_i
          hour += 12 if text[-5..-4] == "PM" && hour != 12
          return hour
        else
          return nil
        end
      end

      def get_game(home_team)
        home_team_games = @games.where(home_team: home_team)
        if home_team_games.size == 2
          if @home_teams.include?(home_team)
            home_team_games.find_by(num: "2")
          else
            @home_teams << home_team
            home_team_games.find_by(num: "1")
          end
        else
          home_team_games.first
        end
      end

  end
end