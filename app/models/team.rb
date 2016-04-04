require 'nokogiri'
require 'open-uri'

class Team < ActiveRecord::Base
	has_many :pitchers
	has_many :hitters

	def fangraph_abbr
		name = self.name
		if name.include?(" ")
			index = name.index(" ")
			return name[0...index] + "%20" + name[index+1..-1]
		end
		return name
	end

	def create_players
		url = "http://www.baseball-reference.com/teams/#{self.abbr}/2015-roster.shtml"
		puts url
		doc = Nokogiri::HTML(open(url))
		hitter = pitcher = identifier = name = bathand = throwhand = nil
		is_pitcher = false
		doc.css("#appearances td").each_with_index do |stat, index|
			text = stat.text
			case index%29
			when 0
				name = text
				identifier = get_alias(stat)
			when 3
				bathand = text
			when 4
				throwhand = text
			when 13
				if text.to_i > 0
					is_pitcher = true
				end
				unless hitter = Hitter.where(:alias => identifier, :game_id => nil).first
					Hitter.create(:name => name, :alias => identifier, :team_id => self.id, :game_id => nil,
						:bathand => bathand, :throwhand => throwhand)
				end
				if is_pitcher
					unless pitcher = Pitcher.where(:alias => identifier, :game_id => nil).first
						Pitcher.create(:name => name, :alias => identifier, :team_id => self.id, :game_id => nil,
							:bathand => bathand, :throwhand => throwhand)
					end
				end
				is_pitcher = false
		 	end		
		end

		doc.css("#40man td").each_with_index do |stat, index|
		 	text = stat.text
		 	case index%14
		 	when 2
		 		name = text
		 	when 4
		 		if text == "Pitcher"
		 			is_pitcher = true
		 		else
		 			is_pitcher = false
		 		end
		 	when 8
		 		bathand = text
		 	when 9
		 		throwhand = text
		 	when 13
		 		unless hitter = Hitter.where(:name => name, :game_id => nil).first
		 			Hitter.create(:name => name, :alias => nil, :team_id => self.id, :game_id => nil,
							:bathand => bathand, :throwhand => throwhand)
				end
				if is_pitcher
		 			unless pitcher = Pitcher.where(:name => name, :game_id => nil).first
		 				Pitcher.create(:name => name, :alias => nil, :team_id => self.id, :game_id => nil,
							:bathand => bathand, :throwhand => throwhand)
		 			end
		 		end
		 	end
		end
	end

	def update_players
		year = Time.now.year - 1
		url = "http://www.baseball-reference.com/teams/#{self.abbr}/#{year}.shtml"
		puts url
		doc = Nokogiri::HTML(open(url))

=begin
	First we check to see if any of the prototypes do not exist. If so, create them.
	Prototype players are not associated with a specific game.
=end
		proto_hitters = Hitter.where(:game_id => nil)
		proto_pitchers = Pitcher.where(:game_id => nil)

		name = identifier = nil

		doc.css("#team_batting tbody td").each_with_index do |stat, index|
			text = stat.text
			case index%28
			when 2
				name = get_name(text)
				identifier = get_alias(stat)
			when 21
				ops = text.to_i
				if hitter = proto_hitters.find_by_name(name)
					unless identifier == ""
						hitter.update_attributes(:alias => identifier, :OPS_L => ops, :OPS_R => ops)
					end
				else
					puts 'Hitter ' + name + ' not found'
				end
			end
		end

		doc.css("#team_pitching tbody td").each_with_index do |stat, index|
			text = stat.text
			case index%34
			when 2
				name = get_name(text)
				identifier = get_alias(stat)
				if pitcher = proto_pitchers.find_by_name(name)
					unless identifier == ""
						pitcher.update_attributes(:alias => identifier)
					end
				else
					puts 'Pitcher ' + name + ' not found'
				end
			end
		end

		url = "http://www.baseball-reference.com/teams/#{self.abbr}/#{year-1}.shtml"
		puts url
		doc = Nokogiri::HTML(open(url))
		name = identifier = nil
		doc.css("#team_batting tbody td").each_with_index do |stat, index|
			text = stat.text
			case index%28
			when 2
				name = get_name(text)
				identifier = get_alias(stat)
			when 21
				ops = text.to_i
				if hitter = proto_hitters.find_by_name(name)
					unless identifier == ""
						hitter.update_attributes(:alias => identifier, :OPS_previous_L => ops, :OPS_previous_R => ops)
					end
				else
					puts 'Hitter ' + name + ' not found'
				end
			end
		end

=begin
	After the prototypes have been created, iterate through the fangraphs urls and update each player's attributes.
	First update the hitters, and then the pitchers.
=end

		urls = Array.new
		urls << "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,5,21,14,16,38,37,50,54,43,44,45&season=#{year}&month=13&season1=#{year}&ind=0&team=#{self.fangraph_id}&rost=1&age=0&filter=&players=0"
		urls << "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,5,21,14,16,38,37,50,54,43,44,45&season=#{year}&month=14&season1=#{year}&ind=0&team=#{self.fangraph_id}&rost=1&age=0&filter=&players=0"
		urls << "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,5,21,14,16,38,37,50,61,43,44,45&season=#{year}&month=2&season1=#{year}&ind=0&team=#{self.fangraph_id}&rost=1&age=0&filter=&players=0"
		urls << "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,5,21,14,16,38,37,50,54,43,44,45&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=#{self.fangraph_id}&rost=1&age=0&filter=&players=0"
		urls << "http://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=c,5,21,14,16,38,37,50,54,43,44,45&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=#{self.fangraph_id}&rost=1&age=0&filter=&players=0"

		ab = sb = bb = so = slg = obp = wOBA = wRC = ld = gb = fb = hitter = name = nil
		urls.each_with_index do |url, url_index|
			doc = Nokogiri::HTML(open(url))
			doc.css(".grid_line_regular").each_with_index do |stat, index|
				text = stat.text
				case index%14
				when 1
					name = text
					fangraph_id = get_fangraph(stat).to_i
					hitter = proto_hitters.find_by_fangraph_id(fangraph_id)
					if hitter == nil
						hitter = proto_hitters.find_by_name(name)
					end
					if hitter == nil
						hitter = proto_hitters.find_by_name(@@nicknames[name])
					end
				when 3
					ab = text.to_i
				when 4
					sb = text.to_i
				when 5
					bb = text.to_i
				when 6
					so = text.to_i
				when 7
					slg = (text.to_f*1000).to_i
				when 8
					obp = (text.to_f*1000).to_i
				when 9
					wOBA = (text.to_f*1000).to_i
				when 10
					wRC = text.to_i
				when 11
					ld = text[0...-2].to_f
				when 12
					gb = text[0...-2].to_f
				when 13
					fb = text[0...-2].to_f
					if hitter
						case url_index
						when 0
							hitter.update_attributes(:team_id => self.id, :AB_L => ab, :SB_L => sb, :BB_L => bb, :SO_L => so, :SLG_L => slg, :OBP_L => obp, :wOBA_L => wOBA, :LD_L => ld, :wRC_L => wRC, :GB_L => gb, :FB_L => fb)
						when 1
							hitter.update_attributes(:team_id => self.id, :AB_R => ab, :SB_R => sb, :BB_R => bb, :SO_R => so, :SLG_R => slg, :OBP_R => obp, :wOBA_R => wOBA, :LD_R => ld, :wRC_R => wRC, :GB_R => gb, :FB_R => fb)
						when 2
							hitter.update_attributes(:team_id => self.id, :AB_14 => ab, :SB_14 => sb, :BB_14 => bb, :SO_14 => so, :SLG_14 => slg, :OBP_14 => obp, :wOBA_14 => wOBA, :LD_14 => ld, :wRC_14 => wRC, :GB_14 => gb, :FB_14 => fb)
						when 3
							hitter.update_attributes(:team_id => self.id, :AB_previous_L => ab, :SB_previous_L => sb, :BB_previous_L => bb, :SO_previous_L => so, :SLG_previous_L => slg, :OBP_previous_L => obp, :wOBA_previous_L => wOBA, :LD_previous_L => ld, :wRC_previous_L => wRC, :GB_previous_L => gb, :FB_previous_L => fb)
						when 4
							hitter.update_attributes(:team_id => self.id, :AB_previous_R => ab, :SB_previous_R => sb, :BB_previous_R => bb, :SO_previous_R => so, :SLG_previous_R => slg, :OBP_previous_R => obp, :wOBA_previous_R => wOBA, :LD_previous_R => ld, :wRC_previous_R => wRC, :GB_previous_R => gb, :FB_previous_R => fb)
						end
					else
						puts name + ' not found'
					end
				end
			end
		end

		urls.clear
		urls << "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year}&month=0&season1=#{year}&ind=0&team=#{self.fangraph_id}&rost=1&age=0&filter=&players=0"
		urls << "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,118&season=#{year-1}&month=0&season1=#{year-1}&ind=0&team=#{self.fangraph_id}&rost=1&age=0&filter=&players=0"
		fip = name = pitcher = nil
		urls.each_with_index do |url, url_index|
			puts url
			doc = Nokogiri::HTML(open(url))
			doc.css(".grid_line_regular").each_with_index do |stat, index|
				text = stat.text
				case index%4
				when 1
					name = text
					fangraph_id = get_fangraph(stat).to_i
					pitcher = proto_pitchers.find_by_fangraph_id(fangraph_id)
					unless pitcher
						pitcher = proto_pitchers.find_by_name(name)
					end
					unless pitcher
						pitcher = proto_pitchers.find_by_name(@@nicknames[name])
					end
				when 3
					fip = text.to_i
					if pitcher
						case url_index
						when 0
							puts '2015'
							puts fip
							pitcher.update_attributes(:team_id => self.id, :FIP => fip)
						when 1
							puts '2014'
							puts fip
							pitcher.update_attributes(:FIP_previous => fip)
						end
		 			else
		 				puts name + ' not found'
		 			end
				end
		 	end
		end

		urls.clear
		urls << "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47,37&season=#{year}&month=13&season1=#{year}&ind=0&team=#{self.fangraph_id}&rost=1&age=0&filter=&players=0"
		urls << "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,36,31,4,14,11,5,38,43,27,47,37&season=#{year}&month=14&season1=#{year}&ind=0&team=#{self.fangraph_id}&rost=1&age=0&filter=&players=0"

		pitcher = ld = whip = ip = so = bb = era = fb = xfip = kbb = woba = gb = name = nil
		urls.each_with_index do |url, url_index|
			doc = Nokogiri::HTML(open(url))
			doc.css(".grid_line_regular").each_with_index do |stat, index|
				text = stat.text
				case index%14
				when 1
					name = text
					fangraph_id = get_fangraph(stat).to_i
					pitcher = proto_pitchers.find_by_fangraph_id(fangraph_id)
					if pitcher == nil
						pitcher = proto_pitchers.find_by_name(name)
					end
					if pitcher == nil
						pitcher = proto_pitchers.find_by_name(@@nicknames[name])
					end
				when 3
					ld = text[0...-2].to_f
				when 4
					whip = text.to_f
				when 5
					ip = text.to_f
				when 6
					so = text.to_i
				when 7
					bb = text.to_i
				when 8
					era = text.to_f
				when 9
					fb = text[0...-2].to_f
				when 10
					xfip = text.to_i
				when 11
					kbb = text.to_f
				when 12
					woba = (text.to_f*1000).to_i
				when 13
					gb = text[0...-2].to_f
					if pitcher
						case url_index
						when 0
							pitcher.update_attributes(:team_id => self.id, :LD_L => ld, :WHIP_L => whip, :IP_L => ip, :SO_L => so, :BB_L => bb, :ERA_L => era, :FB_L => fb, :xFIP_L => xfip, :KBB_L => kbb, :wOBA_L => woba, :GB_L => gb)
						when 1
							pitcher.update_attributes(:LD_R => ld, :WHIP_R => whip, :IP_R => ip, :SO_R => so, :BB_R => bb, :ERA_R => era, :FB_R => fb, :xFIP_R => xfip, :KBB_R => kbb, :wOBA_R => woba, :GB_R => gb)
						end
					else
						puts name + ' not found'
					end
				end
			end
		end

		urls.clear
		urls << "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47,37&season=#{year-1}&month=13&season1=#{year-1}&ind=0&team=#{self.fangraph_id}&rost=1&age=0&filter=&players=0"
		urls << "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,31,4,14,11,38,43,27,47,37&season=#{year-1}&month=14&season1=#{year-1}&ind=0&team=#{self.fangraph_id}&rost=1&age=0&filter=&players=0"

		pitcher = name = fb = xfip = kbb = wOBA = ld = whip = ip = so = bb = gb = nil
		urls.each_with_index do |url, url_index|
			doc = Nokogiri::HTML(open(url))
			doc.css(".grid_line_regular").each_with_index do |stat, index|
				text = stat.text
				case index%12
				when 1
					name = text
					fangraph_id = get_fangraph(stat).to_i
					pitcher = proto_pitchers.find_by_fangraph_id(fangraph_id)
					if pitcher == nil
						pitcher = proto_pitchers.find_by_name(name)
					end
					if pitcher == nil
						pitcher = proto_pitchers.find_by_name(@@nicknames[name])
					end
				when 3
					whip = text.to_f
				when 4
					ip = text.to_f
				when 5
					so = text.to_f
				when 6
					bb = text.to_f
				when 7
					fb = text[0...-2].to_f
				when 8
					xfip = text.to_f
				when 9
					kbb = text.to_f
				when 10
					wOBA = (text.to_f*1000).to_i
				when 11
					gb = text[0...-2].to_f
					if pitcher
						puts pitcher.name
						puts ip.to_s + ' 2014'
						case url_index
						when 0
							pitcher.update_attributes(:team_id => self.id, :IP_previous_L => ip, :FB_previous_L => fb, :xFIP_previous_L => xfip, :KBB_previous_L => kbb, :wOBA_previous_L => wOBA, :GB_previous_L => gb)
						when 1
							pitcher.update_attributes(:IP_previous_R => ip, :FB_previous_R => fb, :xFIP_previous_R => xfip, :KBB_previous_R => kbb, :wOBA_previous_R => wOBA, :GB_previous_R => gb)
						end
					else
						puts name + ' not found'
					end
				end
			end
		end

		pitcher = ld = whip = ip = so = nil
		url = "http://www.fangraphs.com/leaders.aspx?pos=all&stats=pit&lg=all&qual=0&type=c,47,42,13,24,19&season=#{year}&month=3&season1=#{year}&ind=0&team=#{self.fangraph_id}&rost=1&age=0&filter=&players=0"
		doc = Nokogiri::HTML(open(url))
		name = ld = whip = ip = so = bb = nil
		doc.css(".grid_line_regular").each_with_index do |stat, index| #Search through all the information. Use an instance variable to determine which information I want.
			text = stat.text
			case index%8
			when 1
				name = text
				fangraph_id = get_fangraph(stat).to_i
				pitcher = proto_pitchers.find_by_fangraph_id(fangraph_id)
				if pitcher == nil
					pitcher = proto_pitchers.find_by_name(name)
				end
				if pitcher == nil
					pitcher = proto_pitchers.find_by_name(@@nicknames[name])
				end
			when 3
				ld = text[0...-2].to_f
			when 4
				whip = text.to_f
			when 5
				ip = text.to_f
			when 6
				so = text.to_i
			when 7
				bb = text.to_i
				if pitcher
					pitcher.update_attributes(:LD_30 => ld, :WHIP_30 => whip, :IP_30 => ip, :SO_30 => so, :BB_30 => bb)
				else
					puts name + ' not found'
				end
			end
		end
	end


	def fangraphs
		def get_fangraph_id(stat)
			href = stat.child['href']
			first = href.index('=')+1
			last = href.index('&')
			return href[first...last].to_i
		end

		def update_player(proto_players, name, fangraph_id)
			if player = proto_players.find_by_name(name.to_s)
				player.update_attributes(:fangraph_id => fangraph_id)
			elsif player = proto_players.find_by_name(@@nicknames[name])
				player.update_attributes(:fangraph_id => fangraph_id)
			else
				puts name + ' not found'
				puts fangraph_id.to_s + ' id'
			end

		end
		proto_hitters = Hitter.where(:game_id => nil)
		proto_pitchers = Pitcher.where(:game_id => nil)
		url = "http://www.fangraphs.com/depthcharts.aspx?position=ALL&teamid=#{self.fangraph_id}"
		doc = Nokogiri::HTML(open(url))
		doc.css(".depth_chart:nth-child(58) td").each_with_index do |stat, index|
			case index%10
			when 0
				name = stat.child.child.to_s
				unless name.size == 0
					fangraph_id = get_fangraph_id(stat)
					update_player(proto_hitters, name, fangraph_id)
				end
			end
		end

		doc.css(".depth_chart:nth-child(76) td").each_with_index do |stat, index|
			case index%10
			when 0
				name = stat.child.child.to_s
				unless name.size == 0
					fangraph_id = get_fangraph_id(stat)
					update_player(proto_hitters, name, fangraph_id)
					update_player(proto_pitchers, name, fangraph_id)
				end
			end
		end
	end

	private

	def self.set_class_variable
		url = "http://www.fangraphs.com/guts.aspx?type=cn"
		doc = Nokogiri::HTML(open(url))
		hash = {}
		season = woba = woba_scale = r_pa = nil
		doc.css(".grid_line_regular").each_with_index do |stat, index|
			case index%14
			when 0
				season = stat.text.to_i
			when 1
				woba = stat.text.to_f
			when 2
				woba_scale = stat.text.to_f
			when 11
				r_pa = stat.text.to_f
				hash[season] = {woba: woba, woba_scale: woba_scale, r_pa: r_pa}
			end
		end
    	class_variable_set(:@@season_hash, hash)
	end
	set_class_variable


	def get_fangraph(stat)
		href = stat.child['href']
		unless href == nil
			first = href.index('=')+1
			last = href.index('&')
			return href[first...last]
		end
	end

	def get_alias(stat)
		href = stat.child.child['href']
		if href == nil
			href = stat.child['href']
		end
		return href[11..href.index(".")-1]
	end

	def get_name(text)
		if text.include?("(")
			char = text.index("(")
			if text[char-2].match(/^[[:alpha:]]$/)
				name = text[0..char-2]
			else
				name = text[0..char-3]
			end
		elsif text.include?("*") || text.include?("#")
			name = text[0..-2]
		else
			name = text
		end
		return name
	end

	@@nicknames = {
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
		"Jackie Bradley Jr." => "Jackie Bradley",
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
		"Nicholas Goody" => "Nick Goody"
	}




end
