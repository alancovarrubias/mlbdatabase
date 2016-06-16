module Create
  class Games
    include NewShare

    def create(season, team)
      url = "http://www.baseball-reference.com/teams/#{team.abbr}/#{season.year}-schedule-scores.shtml"
      puts url
      doc = download_document(url)
      return unless doc
      doc.css("#team_schedule td").each_slice(21) do |slice|
        next if post_season?(slice[0])
        break if slice[9].text.empty?
        date = find_date(slice[2])
        game_day = GameDay.find_or_create_by(date: date, season: season)
        away_team, home_team = find_away_and_home_teams(slice[4], slice[5], slice[6])
        num = find_game_num(slice[2])
        game = Game.find_or_create_by(game_day: game_day, away_team: away_team, home_team: home_team, num: num)
        puts game.url
      end
    end

    private

      def find_date(date_element)
        href = date_element.child['href']
        Date.parse(href[-10..-1])
      end

      def find_away_and_home_teams(team1, home_or_away, team2)
        team1 = Team.find_by_abbr(convert_team_abbr(team1.text))
        team2 = Team.find_by_abbr(convert_team_abbr(team2.text))
        if home_or_away.text.empty?
          return team2, team1
        else
          return team1, team2
        end
      end

      def find_game_num(date_element)
        children = date_element.children
        if children.size == 1
          '0'
        else
          children.last.to_s[-2]
        end
      end

      def post_season?(element)
        element.text.empty?
      end

      def convert_team_abbr(abbr)
        abbr == "ANA" ? "LAA" : abbr
      end

  end
end