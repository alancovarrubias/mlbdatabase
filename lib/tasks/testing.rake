namespace :testing do

	task :test => :environment do
	end

	task :matchup => :environment do
		require 'nokogiri'
		require 'open-uri'

		def pitcher_info(element)
			name = element.child.text
			identifier = element.child['data-bref']
			fangraph_id = element.child['data-razz'].gsub!(/[^0-9]/, "")
			handedness = element.children[1].text[2]
			return identifier, fangraph_id, name, handedness
		end

		def find_pitcher(proto_pitchers, identifier, fangraph_id, name)
			if identifier.size > 0 && pitcher = proto_pitchers.find_by_alias(identifier)
			elsif fangraph_id && pitcher = proto_pitchers.find_by_fangraph_id(fangraph_id)
			elsif pitcher = proto_pitchers.find_by_name(name)
			else
				return nil
			end
			return pitcher
		end

		def find_pitcher_team(pitcher_index, away_team, home_team)
			if pitcher_index%2 == 0
				away_team
			else
				home_team
			end
		end

		def hitter_info(element)
			name = element.children[1].text
			lineup = element.child.to_s[0]
			handedness = element.children[2].to_s[2]
			position = element.children[2].to_s.match(/\w*$/).to_s
			identifier = element.children[1]['data-bref']
			fangraph_id = element.children[1]['data-razz'].gsub!(/[^0-9]/, "")
			return identifier, fangraph_id, name, handedness, lineup, position
		end

		def find_hitter(proto_hitters, identifier, fangraph_id, name)
			if identifier.size > 0 && hitter = proto_hitters.find_by_alias(identifier)
			elsif fangraph_id && hitter = proto_hitters.find_by_fangraph_id(fangraph_id)
			elsif hitter = proto_hitters.find_by_name(name)
			else
				return nil
			end
			return hitter
		end

		def find_hitter_team(hitter_index, away_team, home_team, away_lineup, home_lineup)
			if away_lineup && home_lineup
				if hitter_index/9 == 0
					away_team
				else
					home_team
				end
			elsif away_lineup
				away_team
			else
				home_team
			end
		end

		def create_pitcher(pitcher, game)
			Pitcher.create(:game_id => game.id, :team_id => pitcher.team.id, :name => pitcher.name, :alias => pitcher.alias, :fangraph_id => pitcher.fangraph_id, :bathand => pitcher.bathand,
							:throwhand => pitcher.throwhand, :starter => true, :FIP => pitcher.FIP, :LD_L => pitcher.LD_L, :WHIP_L => pitcher.WHIP_L, :IP_L => pitcher.IP_L,
							:SO_L => pitcher.SO_L, :BB_L => pitcher.BB_L, :ERA_L => pitcher.ERA_L, :wOBA_L => pitcher.wOBA_L, :FB_L => pitcher.FB_L, :xFIP_L => pitcher.xFIP_L,
							:KBB_L => pitcher.KBB_L, :LD_R => pitcher.LD_R, :WHIP_R => pitcher.WHIP_R, :IP_R => pitcher.IP_R, :SO_R => pitcher.SO_R, :BB_R => pitcher.BB_R,
							:ERA_R => pitcher.ERA_R, :wOBA_R => pitcher.wOBA_R, :FB_R => pitcher.FB_R, :xFIP_R => pitcher.xFIP_R, :KBB_R => pitcher.KBB_R, :GB_R => pitcher.GB_R,
							:GB_L => pitcher.GB_L, :LD_30 => pitcher.LD_30, :WHIP_30 => pitcher.WHIP_30, :IP_30 => pitcher.IP_30, :SO_30 => pitcher.SO_30, :BB_30 => pitcher.BB_30, 
							:FIP_previous => pitcher.FIP_previous, :FB_previous_L => pitcher.FB_previous_L, :xFIP_previous_L => pitcher.xFIP_previous_L, :KBB_previous_L => pitcher.KBB_previous_L,
							:wOBA_previous_L => pitcher.wOBA_previous_L, :FB_previous_R => pitcher.FB_previous_R, :xFIP_previous_R => pitcher.xFIP_previous_R, :KBB_previous_R => pitcher.KBB_previous_R,
							:wOBA_previous_R => pitcher.wOBA_previous_R, :GB_previous_L => pitcher.GB_previous_L, :GB_previous_R => pitcher.GB_previous_R)

		end

		def create_hitter(hitter, game)
			Hitter.create(:game_id => game.id, :team_id => hitter.team.id, :name => hitter.name, :alias => hitter.alias, :fangraph_id => hitter.fangraph_id, :bathand => hitter.bathand,
							:throwhand => hitter.throwhand, :lineup => hitter.lineup, :starter => true, :SB_L => hitter.SB_L, :wOBA_L => hitter.wOBA_L,
							:OBP_L => hitter.OBP_L, :SLG_L => hitter.SLG_L, :AB_L => hitter.AB_L, :BB_L => hitter.BB_L, :SO_L => hitter.SO_L, :LD_L => hitter.LD_L,
							:wRC_L => hitter.wRC_L, :SB_R => hitter.SB_R, :wOBA_R => hitter.wOBA_R, :OBP_R => hitter.OBP_R, :SLG_R => hitter.SLG_R, :AB_R => hitter.AB_R,
							:BB_R => hitter.BB_R, :SO_R => hitter.SO_R, :LD_R => hitter.LD_R, :wRC_R => hitter.wRC_R, :SB_14 => hitter.SB_14, :wOBA_14 => hitter.wOBA_14,
							:OBP_14 => hitter.OBP_14, :SLG_14 => hitter.SLG_14, :AB_14 => hitter.AB_14, :BB_14 => hitter.BB_14, :SO_14 => hitter.SO_14, :LD_14 => hitter.LD_14,
							:wRC_14 => hitter.wRC_14, :SB_previous_L => hitter.SB_previous_L, :wOBA_previous_L => hitter.wOBA_previous_L, :OBP_previous_L => hitter.OBP_previous_L,
							:SLG_previous_L => hitter.SLG_previous_L, :AB_previous_L => hitter.AB_previous_L, :BB_previous_L => hitter.BB_previous_L, :SO_previous_L => hitter.SO_previous_L,
							:LD_previous_L => hitter.LD_previous_L, :wRC_previous_L => hitter.wRC_previous_L, :SB_previous_R => hitter.SB_previous_R, :wOBA_previous_R => hitter.wOBA_previous_R, 
							:OBP_previous_R => hitter.OBP_previous_R, :SLG_previous_R => hitter.SLG_previous_R, :AB_previous_R => hitter.AB_previous_R, :BB_previous_R => hitter.BB_previous_R,
							:SO_previous_R => hitter.SO_previous_R, :LD_previous_R => hitter.LD_previous_R, :wRC_previous_R => hitter.wRC_previous_R)
		end

		def element_type(element)
			element_class = element['class']
			case element_class
			when /game-time/
				type = 'time'
			when /no-lineup/
				type = 'no lineup'
			when /team-name/
				type = 'lineup'
			else
				if element.children.size == 3
					type = 'hitter'
				else
					type = 'pitcher'
				end
			end
		end

		url = "http://www.baseballpress.com/lineups"
		doc = Nokogiri::HTML(open(url))
		game_index = -1
		away_lineup = home_lineup = false
		away_team = home_team = nil
		team_index = pitcher_index = hitter_index = 0
		doc.css(".players div, .team-name+ div, .team-name, .game-time").each_with_index do |element, index|
			type = element_type(element)
			case type
			when 'time'
				game_index += 1
				hitter_index = 0
			when 'lineup'
				if team_index%2 == 0
					away_team = Team.find_by_name(element.text)
					away_lineup = true
				else
					home_team = Team.find_by_name(element.text)
					home_lineup = true
				end
				team_index += 1
			when 'no-lineup'
				if team_index%2 == 0
					away_team = Team.find_by_name(element.text)
					away_lineup = false
				else
					home_team = Team.find_by_name(element.text)
					home_lineup = false
				end
				team_index += 1
			when 'pitcher'
				proto_pitchers = Pitcher.where(:game_id => nil)
				# Skip any pitchers that aren't announced, otherwise find the prototype pitcher
				if element.text == "TBD"
					pitcher_index += 1
					next
				else
					identifier, fangraph_id, name, handedness = pitcher_info(element)
					pitcher = find_pitcher(proto_pitchers, identifier, fangraph_id, name)
				end
				team = find_pitcher_team(pitcher_index, away_team, home_team)
				# If prototype pitcher not found, create one
				unless pitcher
					pitcher = Pitcher.create(:game_id => nil, :team_id => team.id, :starter => true, :name => name, :alias => identifier, :fangraph_id => fangraph_id, :throwhand => handedness)
				else
					pitcher.update_attributes(:team_id => team.id, :starter => true, :name => name, :alias => identifier, :fangraph_id => fangraph_id, :throwhand => handedness)
				end
				pitcher_index += 1
			when 'hitter'
				proto_hitters = Hitter.where(:game_id => nil)
				# look for the prototype hitter
				identifier, fangraph_id, name, handedness, lineup, position = hitter_info(element)
				hitter = find_hitter(proto_hitters, identifier, fangraph_id, name)
				team = find_hitter_team(hitter_index, away_team, home_team, away_lineup, home_lineup)
				# If prototype hitter not found, create one
				unless hitter
					hitter = Hitter.create(:game_id => nil, :team_id => team.id, :starter => true, :name => name, :alias => identifier, :fangraph_id => fangraph_id, :bathand => handedness, :lineup => lineup)
				else
					hitter.update_attributes(:team_id => team.id, :starter => true, :name => name, :alias => identifier, :fangraph_id => fangraph_id, :bathand => handedness, :lineup => lineup)
				end
				hitter_index += 1
			end

			if pitcher
				create_pitcher(pitcher, games[game_index])
			end
			if hitter
				create_hitter(hitter, games[game_index])
			end
		end
	end

end