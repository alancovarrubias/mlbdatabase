class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
	protect_from_forgery with: :exception
	
	private

	def confirm_logged_in
		unless session[:user_id]
			flash[:notice] = "Please log in."
			redirect_to(:controller => 'access', :action => 'login')
			return false
		else
			return true
		end
	end

	def getCurrentStats(lineup)
		current_lineup = Array.new

		lineup.each_with_index do |hitter, index|
			current_hitter = Hitter.where(:game_id => nil, :alias => hitter.alias).first
			if hitter.team.id == current_hitter.team.id
				current_hitter.update_attributes(:lineup => index+1)
				current_lineup << current_hitter
			end
		end

		return current_lineup

	end




	def findProjectedLineup(today_game, home, away_pitcher, home_pitcher)

		home_team = today_game.home_team
		away_team = today_game.away_team
		home_pitcher = home_pitcher.first
		away_pitcher = away_pitcher.first

		if home
			if away_pitcher == nil
				return Array.new
			end
			throwhand = away_pitcher.throwhand
			pitcher = home_pitcher
			team = home_team
			games = Game.where("(home_team_id = #{home_team.id} OR away_team_id = #{home_team.id}) AND id < #{today_game.id}").order("id DESC")
		else
			if home_pitcher == nil
				return Array.new
			end
			throwhand = home_pitcher.throwhand
			pitcher = away_pitcher
			team = away_team
			games = Game.where("(home_team_id = #{away_team.id} OR away_team_id = #{away_team.id}) AND id < #{today_game.id}").order("id DESC")
		end

		games.each do |game|
			if home_team == game.home_team
				opp_pitcher = game.pitchers.where(:team_id => game.away_team.id).first
			else
				opp_pitcher = game.pitchers.where(:team_id => game.home_team.id).first
			end

			if opp_pitcher == nil
				next
			end

			if opp_pitcher.throwhand == ''
				opp_pitcher = Pitcher.where(:game_id => nil, :alias => opp_pitcher.alias).first
			end

			if opp_pitcher.throwhand == throwhand
				hitter = Hitter.find_by_name(pitcher.name)
				array = game.hitters
				if home_team.league == 'NL'
					array = array[0...-1]
					array << hitter
				end
				return array
			end
		end
	end

	def addTotalStats(hitters)
		total = Hitter.new(:name => 'Total')
		sb_L = wOBA_L = obp_L = slg_L = ab_L = bb_L = so_L = ld_L = wRC_L = sb_R = wOBA_R = obp_R = slg_R = ab_R = bb_R = so_R = ld_R = wRC_R = 0
		sb_14 = wOBA_14 = obp_14 = slg_14 = ab_14 = bb_14 = so_14 = ld_14 = wRC_14 = 0
		sb_previous_L = wOBA_previous_L = obp_previous_L = slg_previous_L = ab_previous_L = bb_previous_L = so_previous_L = ld_previous_L = wRC_previous_L = sb_previous_R = wOBA_previous_R = obp_previous_R = slg_previous_R = ab_previous_R = bb_previous_R = so_previous_R = ld_previous_R = wRC_previous_R = 0
		hitters.each do |hitter|
			sb_L += hitter.SB_L
			wOBA_L += hitter.wOBA_L
			obp_L += hitter.OBP_L
			slg_L += hitter.SLG_L
			ab_L += hitter.AB_L
			bb_L += hitter.BB_L
			so_L += hitter.SO_L
			ld_L += hitter.LD_L
			wRC_L += hitter.wRC_L
			sb_R += hitter.SB_R
			wOBA_R += hitter.wOBA_R
			obp_R += hitter.OBP_R
			slg_R += hitter.SLG_R
			ab_R += hitter.AB_R
			bb_R += hitter.BB_R
			so_R += hitter.SO_R
			ld_R += hitter.LD_R
			wRC_R += hitter.wRC_R
			sb_14 += hitter.SB_14
			wOBA_14 += hitter.wOBA_14
			obp_14 += hitter.OBP_14
			slg_14 += hitter.SLG_14
			ab_14 += hitter.AB_14
			bb_14 += hitter.BB_14
			so_14 += hitter.SO_14
			ld_14 += hitter.LD_14
			wRC_14 += hitter.wRC_14
			sb_previous_L += hitter.SB_previous_L
			wOBA_previous_L += hitter.wOBA_previous_L
			obp_previous_L += hitter.OBP_previous_L
			slg_previous_L += hitter.SLG_previous_L
			ab_previous_L += hitter.AB_previous_L
			bb_previous_L += hitter.BB_previous_L
			so_previous_L += hitter.SO_previous_L
			ld_previous_L += hitter.LD_previous_L
			wRC_previous_L += hitter.wRC_previous_L
			sb_previous_R += hitter.SB_previous_R
			wOBA_previous_R += hitter.wOBA_previous_R
			obp_previous_R += hitter.OBP_previous_R
			slg_previous_R += hitter.SLG_previous_R
			ab_previous_R += hitter.AB_previous_R
			bb_previous_R += hitter.BB_previous_R
			so_previous_R += hitter.SO_previous_R
			ld_previous_R += hitter.LD_previous_R
			wRC_previous_R += hitter.wRC_previous_R
		end

		total.update_attributes(:SB_L => sb_L, :wOBA_L => wOBA_L,
			:OBP_L => obp_L, :SLG_L => slg_L, :AB_L => ab_L, :BB_L => bb_L, :SO_L => so_L, :LD_L => ld_L.round,
			:wRC_L => wRC_L, :SB_R => sb_R, :wOBA_R => wOBA_R, :OBP_R => obp_R, :SLG_R => slg_R, :AB_R => ab_R,
			:BB_R => bb_R, :SO_R => so_R, :LD_R => ld_R.round, :wRC_R => wRC_R, :SB_14 => sb_14, :wOBA_14 => wOBA_14,
			:OBP_14 => obp_14, :SLG_14 => slg_14, :AB_14 => ab_14, :BB_14 => bb_14, :SO_14 => so_14, :LD_14 => ld_14.round,
			:wRC_14 => wRC_14, :SB_previous_L => sb_previous_L, :wOBA_previous_L => wOBA_previous_L, :OBP_previous_L => obp_previous_L,
			:SLG_previous_L => slg_previous_L, :AB_previous_L => ab_previous_L, :BB_previous_L => bb_previous_L, :SO_previous_L => so_previous_L,
			:LD_previous_L => ld_previous_L.round, :wRC_previous_L => wRC_previous_L, :SB_previous_R => sb_previous_R, :wOBA_previous_R => wOBA_previous_R, 
			:OBP_previous_R => obp_previous_R, :SLG_previous_R => slg_previous_R, :AB_previous_R => ab_previous_R, :BB_previous_R => bb_previous_R,
			:SO_previous_R => so_previous_R, :LD_previous_R => ld_previous_R.round, :wRC_previous_R => wRC_previous_R)

		return total
	end
end
