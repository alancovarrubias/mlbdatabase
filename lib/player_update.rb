module PlayerUpdate

  include NewShare

	def parse_identity(element)
	  href = element.child.child['href']
	  unless href
			href = element.child['href']
	  end
	  href[11..href.index(".")-1]
	end

	def team_pitchers(doc, game, team)
	  name = identity = ip = h = r = bb = nil
	  doc.css("##{team.css}pitching tbody td").each_with_index do |element, index|
			case index
			when 0
			  name = element.child.text
			  identity = parse_identity(element)
			when 1
			  ip = element.text.to_f
			when 2
			  h = element.text.to_i
			when 3
			  r = element.text.to_i
			when 5
			  bb = element.text.to_i
			when 6
			  if player = Player.search(name, identity)
			  	@pitchers << player
			  	lancer = game.lancers.where(starter: true).find_by(player_id: player.id)
			  	unless lancer
			  	  lancer = player.create_lancer(game.game_day.season, team, game)
			  	  lancer.update(starter: true)
			  	end
	  	    # puts lancer.player.name
  		    lancer.update(ip: ip, h: h, r: r, bb: bb)
			  end
			  break
			end
	  end
	end

  def game_pitchers(game_day)
    game_day.games.each do |game|
    	@pitchers = Array.new
	    url = "http://www.baseball-reference.com/boxes/#{game.home_team.game_abbr}/#{game.url}.shtml"
	    puts url
	    doc = download_document(url)
	    team_pitchers(doc, game, game.away_team)
	    team_pitchers(doc, game, game.home_team)
	    player_ids = @pitchers.map { |player| player.id }
	    game.lancers.where(starter: true).each do |lancer|
	      unless player_ids.include? lancer.player_id
	      	puts "#{lancer.player.name} destroyed"
	      	lancer.destroy
	      end
	    end
	  end
	end

end