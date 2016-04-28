class Player < ActiveRecord::Base
  validates :identity,    uniqueness: :true, allow_blank: true
  validates :fangraph_id, uniqueness: :true, allow_nil: true
  belongs_to :team
  has_many :lancers, dependent: :destroy
  has_many :batters, dependent: :destroy

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

  def create_batter(season, team=nil, game=nil)
    if game
      unless batter = self.batters.where(season_id: season.id, team_id: team.id, game_id: game.id).first
        batter = Batter.create(player_id: self.id, season_id: season.id, team_id: team.id, game_id: game.id)
        puts "#{self.name} batter created for #{game.url}"
        batter.create_game_stats
      end
    else
      unless batter = self.batters.where(season_id: season.id, team_id: nil, game_id: nil).first
        batter = Batter.create(player_id: self.id, season_id: season.id)
      end
    end
    return batter
  end

  def create_lancer(season, team=nil, game=nil)
    if game
      unless lancer = self.lancers.where(season_id: season.id, team_id: team.id, game_id: game.id).first
        lancer = Lancer.create(player_id: self.id, season_id: season.id, team_id: team.id, game_id: game.id)
        puts "#{self.name} lancer created for #{game.url}"
        lancer.create_game_stats
      end
    else
      unless lancer = self.lancers.where(season_id: season.id, team_id: nil, game_id: nil).first
        lancer = Lancer.create(player_id: self.id, season_id: season.id)
      end
    end
    return lancer
  end

  def find_batter(season, team=nil, game=nil)
    if game
      return self.batters.where(season_id: season.id, team_id: team.id, game_id: game.id).first
    else
      return self.batters.where(season_id: season.id, team_id: nil, game_id: nil).first
    end
  end

  def find_lancer(season, team=nil, game=nil)
    if game
      return self.lancers.where(season_id: season.id, team_id: team.id, game_id: game.id).first
    else
      return self.lancers.where(season_id: season.id, team_id: nil, game_id: nil).first
    end
  end

  def game_day_lancers(game_day)
    game_ids = game_day.games.map { |game| game.id }
    Lancer.where(player_id: self.id, game_id: game_ids)
  end

  private

  @nicknames = {
    "Jonathon Niese" => "Jon Niese",
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
    "John Barbato" => "Johnny Barbato",
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
