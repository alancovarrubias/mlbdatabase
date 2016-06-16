module Miscellaneous

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