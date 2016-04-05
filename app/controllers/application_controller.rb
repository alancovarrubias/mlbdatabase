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

	def get_current_stats(lineup)

		current_lineup = Array.new

		proto_hitters = Hitter.proto_hitters
		lineup.each_with_index do |hitter, index|
			current_hitter = proto_hitters.where(:alias => hitter.alias).first
			if hitter.team.id == current_hitter.team.id
				current_hitter.update_attributes(lineup: index+1)
				current_lineup << current_hitter
			end
		end

		return current_lineup

	end

  def find_projected_lineup(this_game, team, opp_pitcher)

    unless opp_pitcher
	  return Array.new
    end

	# Grab previous games where the team played
	games = Game.where("(home_team_id = #{team.id} OR away_team_id = #{team.id}) AND id < #{this_game.id}").order("id DESC")

	games.each do |game|

	  if team == game.home_team
	    game_opp_pitcher = game.pitchers.where(team_id: game.away_team.id, starter: true).first
	  else
		game_opp_pitcher = game.pitchers.where(team_id: game.home_team.id, starter: true).first
	  end

	  if game_opp_pitcher == nil || game.hitters.size != 18
		next
	  end

	  if game_opp_pitcher.throwhand == ''
		game_opp_pitcher = Pitcher.proto_pitchers.find_by_alias(opp_pitcher.alias)
	  end

	  if game_opp_pitcher.throwhand == opp_pitcher.throwhand
		game_hitters = game.hitters.where(:team_id => team.id)
		return game_hitters
	  end

	end

	return Array.new

  end

  def add_total_stats(hitters)
  	woba_l = hitters.sum(:wOBA_L)
  	woba_r = hitters.sum(:wOBA_R)
  	ops_l = hitters.sum(:OPS_L)
  	ops_r = hitters.sum(:OPS_R)
  	ab_l = hitters.sum(:AB_L)
  	ab_r = hitters.sum(:AB_R)
  	so_l = hitters.sum(:SO_L)
  	so_r = hitters.sum(:SO_R)
	bb_l = hitters.sum(:SO_L)
  	bb_r = hitters.sum(:SO_R)
  	fb_l = hitters.sum(:FB_L)
  	fb_r = hitters.sum(:FB_R)
  	gb_l = hitters.sum(:GB_L)
  	gb_r = hitters.sum(:GB_R)
  	ld_l = hitters.sum(:LD_L)
  	ld_r = hitters.sum(:LD_R)
  	woba_14 = hitters.sum(:wOBA_14)
  	ops_14 = hitters.sum(:OPS_14)
  	ab_14 = hitters.sum(:AB_14)
  	so_14 = hitters.sum(:SO_14)
	bb_14 = hitters.sum(:SO_14)
  	fb_14 = hitters.sum(:FB_14)
  	gb_14 = hitters.sum(:GB_14)
  	ld_14 = hitters.sum(:LD_14)
  	woba_previous_l = hitters.sum(:wOBA_previous_L)
  	woba_previous_r = hitters.sum(:wOBA_previous_R)
  	ops_previous_l = hitters.sum(:OPS_previous_L)
  	ops_previous_r = hitters.sum(:OPS_previous_R)
  	ab_previous_l = hitters.sum(:AB_previous_L)
  	ab_previous_r = hitters.sum(:AB_previous_R)
  	so_previous_l = hitters.sum(:SO_previous_L)
  	so_previous_r = hitters.sum(:SO_previous_R)
	bb_previous_l = hitters.sum(:SO_previous_L)
  	bb_previous_r = hitters.sum(:SO_previous_R)
  	fb_previous_l = hitters.sum(:FB_previous_L)
  	fb_previous_r = hitters.sum(:FB_previous_R)
  	gb_previous_l = hitters.sum(:GB_previous_L)
  	gb_previous_r = hitters.sum(:GB_previous_R)
  	ld_previous_l = hitters.sum(:LD_previous_L)
  	ld_previous_r = hitters.sum(:LD_previous_R)
  	wrc_l = hitters.sum(:wRC_L)
  	wrc_r = hitters.sum(:wRC_R)
  	wrc_14 = hitters.sum(:wRC_14)
  	wrc_previous_l = hitters.sum(:wRC_previous_L)
  	wrc_previous_r = hitters.sum(:wRC_previous_R)



  	total = Hitter.new(name: "Total", wOBA_L: woba_l, wOBA_R: woba_r, wOBA_14: woba_14, wOBA_previous_L: woba_previous_l, wOBA_previous_R: woba_previous_r,
  		OPS_L: ops_l, OPS_R: ops_r, OPS_14: ops_14, OPS_previous_L: ops_previous_l, OPS_previous_R: ops_previous_r,
  		AB_L: ab_l, AB_R: ab_r, AB_14: ab_14, AB_previous_L: ab_previous_l, AB_previous_R: ab_previous_r,
  		SO_L: so_l, SO_R: so_r, SO_14: so_14, SO_previous_L: so_previous_l, SO_previous_R: so_previous_r,
  		BB_L: bb_l, BB_R: bb_r, BB_14: bb_14, BB_previous_L: bb_previous_l, BB_previous_R: bb_previous_r,
  		FB_L: fb_l, FB_R: fb_r, FB_14: fb_14, FB_previous_L: fb_previous_l, FB_previous_R: fb_previous_r,
  		GB_L: gb_l, GB_R: gb_r, GB_14: gb_14, GB_previous_L: gb_previous_l, GB_previous_R: gb_previous_r,
  		LD_L: ld_l, LD_R: ld_r, LD_14: ld_14, LD_previous_L: ld_previous_l, LD_previous_R: ld_previous_r,
  		wRC_L: wrc_l, wRC_R: wrc_r, wRC_14: wrc_14, wRC_previous_L: wrc_previous_l, wRC_previous_R: wrc_previous_r)
  	return total

  end
end
