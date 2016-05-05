module Create

  class Players

  	include NewShare

  	def initialize(season, team)
  	  @season = season
  	  @team = team
  	end

  	def create
	  puts "Create " + @team.name + " " + year.to_s + " Players"
	  url = "http://www.baseball-reference.com/teams/#{@team.abbr}/#{@season.year}-roster.shtml"
	  doc = download_document(url)
	  modulus = get_modulus
	  name = identity = bathand = throwhand = nil
	  doc.css("#appearances td").each_with_index do |element, index|
		text = element.text
		case index%modulus
		when 0
		  name = text
		  identity = parse_identity(element)
		when 3
		  bathand = text
		when 4
		  throwhand = text
		when 13
		  is_pitcher = (text.to_i != 0)
		  unless player = Player.search(name, identity)
		  	player = Player.create(name: name, identity: identity)
		  	puts "Player " + player.name + " created"
		  end
		  player.update(team: @team, identity: identity, bathand: bathand, throwhand: throwhand)
		  player.create_batter(season)
		  if is_pitcher
		  	player.create_lancer(season)
		  end
		  check_exceptions(player)
		end
	  end
	end

	  # Updates fangraph_ids of players for easier updating
    def fangraphs(team)
	  url = "http://www.fangraphs.com/depthcharts.aspx?position=ALL&teamid=#{team.fangraph_id}"
	  doc = Nokogiri::HTML(open(url))
	  doc.css(".depth_chart:nth-child(58) td").each_with_index do |stat, index|
	    case index%10
	    when 0
		  name = stat.child.child.to_s
		  unless name.size == 0
		    fangraph_id = parse_fangraph_id(stat)
		    player = Player.search(name, nil, fangraph_id)
		    if player
		  	  player.update_attributes(fangraph_id: fangraph_id)
		    else
		  	  puts "Player " + name + " not found"
		    end
		  end
	    end
	  end

	  doc.css(".depth_chart:nth-child(76) td").each_with_index do |stat, index|
	    case index%10
	    when 0
	      name = stat.child.child.to_s
	      unless name.size == 0
		    fangraph_id = parse_fangraph_id(stat)
		    player = Player.search(name, nil, fangraph_id)
		    if player
		  	  player.update_attributes(fangraph_id: fangraph_id)
		    else
		  	  puts "Player " + name + " not found"
		    end
	      end
	    end
	  end
    end

	private


	  def check_exceptions(player)
        if player.name == "Enrique Hernandez"
      	  player.update_attributes(fangraph_id: 10472)
        end
      end

      def get_modulus
	    if @season.year == Time.now.year
	      28
	    else
	      29
	    end
	  end

	  def parse_identity(element)
	    href = element.child.child['href']
	    if href == nil
		  href = element.child['href']
	    end
	    href[11..href.index(".")-1]
	  end

	  def parse_fangraph_id(element)
	    href = element.child['href']
	    if href
		  first = href.index('=')+1
		  last = href.index('&')
		  return href[first...last].to_i
	    end
	  end

  end

end