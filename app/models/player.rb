class Player < ActiveRecord::Base
  validates :identity,    uniqueness: :true, allow_blank: true
  validates :fangraph_id, uniqueness: :true, allow_nil: true
  has_many :batter_stats
  has_many :pitcher_stats
  belongs_to :team

  def self.starters
  	Player.where(starter: true)
  end

  def self.bullpen
    Player.where(bullpen: true)
  end

  def self.search(name, identity=nil, fangraph_id=0)
    if @nicknames[name]
      name = @nicknames[name]
    end
  	if player = Player.find_by_name(name)
      return player
    elsif identity && player = Player.find_by_identity(identity)
      return player
    elsif fangraph_id != 0 && player = Player.find_by_fangraph_id(fangraph_id)
      return player
    end
    return nil
  end

  def season_pitcher_stats(season)
    if self.pitcher_stats.where(season_id: season.id, game_id: nil).size == 0
      create_season_pitcher_stats(season)
    end
    return self.pitcher_stats.where(season_id: season.id, game_id: nil)
  end

  def season_batter_stats(season)
    if self.batter_stats.where(season_id: season.id, game_id: nil).size == 0
      create_season_batter_stats(season)
    end
    return self.batter_stats.where(season_id: season.id, game_id: nil)
  end

  def game_pitcher_stats(game)
    if self.pitcher_stats.where(game_id: game.id).empty?
      season = Season.find_by_year(game.game_day.year)
      create_game_pitcher_stats(game, season)
    end
  	return self.pitcher_stats.where(game_id: game.id)
  end

  def game_batter_stats(game)
    if self.batter_stats.where(game_id: game.id).empty?
      season = Season.find_by_year(game.game_day.year)
      create_game_batter_stats(game, season)
    end
  	return self.batter_stats.where(game_id: game.id)
  end


  private

  def create_season_pitcher_stats(season)
    PitcherStat.create(player_id: self.id, team_id: self.team.id, season_id: season.id, range: "Season", handedness: "L")
    PitcherStat.create(player_id: self.id, team_id: self.team.id, season_id: season.id, range: "Season", handedness: "R")
    PitcherStat.create(player_id: self.id, team_id: self.team.id, season_id: season.id, range: "30 Days", handedness: "")
  end

  def create_season_batter_stats(season)
    BatterStat.create(player_id: self.id, team_id: self.team.id, season_id: season.id, range: "Season", handedness: "L")
    BatterStat.create(player_id: self.id, team_id: self.team.id, season_id: season.id, range: "Season", handedness: "R")
    BatterStat.create(player_id: self.id, team_id: self.team.id, season_id: season.id, range: "14 Days", handedness: "")
  end

  def create_game_pitcher_stats(game, season)
    self.season_pitcher_stats(season).each do |pitcher_stat|
      game_pitcher_stat = pitcher_stat.dup
      game_pitcher_stat.game_id = game.id
      game_pitcher_stat.save
    end
  end

  def create_game_batter_stats(game, season)
    self.season_batter_stats(season).each do |batter_stat|
      game_batter_stat = batter_stat.dup
      game_batter_stat.game_id = game.id
      game_batter_stat.save
    end
  end

  @nicknames = {
    "Phil Gosselin" => "Philip Gosselin",
    "Thomas Pham" => "Tommy Pham",
    "Zachary Heathcott" => "Slade Heathcott",
    "Daniel Burawa" => "Danny Burawa",
    "Kenneth Roberts" => "Kenny Roberts",
    "Dennis Tepera" => "Ryan Tepera",
    "John Leathersich" => "Jack Leathersich",
    "Hyun-Jin Ryu" => "Hyun-jin Ryu",
    "Tom Layne" => "Tommy Layne",
    "Nathan Karns" => "Nate Karns",
    "Matt Joyce" => "Matthew Joyce",
    "Michael Morse" => "Mike Morse",
    "Steven Souza Jr." => "Steven Souza",
    "Reynaldo Navarro" => "Rey Navarro",
    "Jung-ho Kang" => "Jung Ho Kang",
    "Edward Easley" => "Ed Easley",
    "JR Murphy" => "John Ryan Murphy",
    "Deline Deshields Jr." => "Delin DeShields",
    "Steve Tolleson" => "Steven Tolleson",
    "Daniel Dorn" => "Dan Dorn",
    "Nicholas Tropeano" => "Nick Tropeano",
    "Michael Montgomery" => "Mike Montgomery",
    "Matthew Tracy" => "Matt Tracy",
    "Andrew Schugel" => "A.J. Schugel",
    "Matthew Wisler" => "Matt Wisler",
    "Sugar Marimon" => "Sugar Ray Marimon",
    "Nate Adcock" => "Nathan Adcock",
    "Samuel Deduno" => "Sam Deduno",
    "Joshua Ravin" => "Josh Ravin",
    "Michael Strong" => "Mike Strong",
    "Samuel Tuivailala" => "Sam Tuivailala",
    "Joseph Donofrio" => "Joey Donofrio",
    "Mitchell Harris" => "Mitch Harris",
    "Christopher Rearick" => "Chris Rearick",
    "Jeremy Mcbryde" => "Jeremy McBryde",
    "Daniel Robertson" => "Dan Robertson",
    "Jorge de la Rosa" => "Jorge De La Rosa",
    "Rubby de la Rosa" => "Rubby De La Rosa",
    "Zachary Davies" => "Zach Davies",
    "Zachary Godley" => "Zack Godley",
    "Francelis Montas" => "Frankie Montas",
    "Jonathan Gray" => "Jon Gray",
    "Gregory Bird" => "Greg Bird",
    "Nicholas Goody" => "Nick Goody",
    "KikÃÂ© Hernandez" => "Enrique Hernandez",
    "Seung Oh" => "Seung-hwan Oh",
    "Timothy Melville" => "Tim Melville",
    "Johnny Barbato" => "John Barbato",
    "Anthony Barnette" => "Tony Barnette",
    "Luis David Perdomo" => "Luis Perdomo",
    "Dae-Ho Lee" => "Dae-ho Lee",
    "Joseph Biagini" => "Joe Biagini",
    "Christopher Devenski" => "Chris Devenski",
    "Matthew Buschmann" => "Matt Buschmann",
    "Melvin Upton Jr." => "Melvin Upton",
    "Jackie Bradley Jr." => "Jackie Bradley",
    "John Barbato" => "Johnny Barbato"
  }

end
