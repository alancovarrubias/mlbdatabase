module Create
  class Seasons

    def create
      2017.downto(2001) do |year|
        season = Season.find_or_create_by(year: year)
        add_teams_to_season(season)
      end
    end

    private

      def add_teams_to_season(season)
        Team.limit(30).each do |team|
          season.teams << correct_team(season, team)
        end
      end

      def correct_team(season, team)
        year = season.year
        if team.name == "Angels" && year <= 2004
          Team.find_by_abbr("ANA")
        elsif team.name == "Marlins" && year <= 2011
          Team.find_by_abbr("FLA")
        elsif team.name == "Nationals" && year <= 2004
          Team.find_by_abbr("MON")
        elsif team.name == "Rays" && year <= 2007
          Team.find_by_abbr("TBD")
        else
          team
        end
      end
  end
end
