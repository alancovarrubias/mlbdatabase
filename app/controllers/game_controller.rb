class GameController < ApplicationController

	def matchup
		
		require 'date'


		@game = Game.find_by_id(params[:id])
		@away_team = @game.away_team
		@home_team = @game.home_team

		hitter_box_scores = @game.hitter_box_scores
		pitcher_box_scores = @game.pitcher_box_scores

		@away_hitting_boxscores = hitter_box_scores.where(:home => false)
		@away_pitching_boxscores = pitcher_box_scores.where(:home => false)

		@home_hitting_boxscores = hitter_box_scores.where(:home => true)
		@home_pitching_boxscores = pitcher_box_scores.where(:home => true)

		@innings = Array.new
		@away_score = Array.new
		@home_score = Array.new

		@game.innings.each do |inning|
			@innings << inning.number
			@away_score << inning.away
			@home_score << inning.home
		end

		today_bool = false
		@tomorrow_bool = false

		year = Time.now.year.to_s
		month = Time.now.month.to_s
		day = Time.now.day.to_s

		if year == params[:year] && month == params[:month] && day == params[:day]
			today_bool = true
		end


		year = Time.now.tomorrow.year.to_s
		month = Time.now.tomorrow.month.to_s
		day = Time.now.tomorrow.day.to_s

		if year == params[:year] && month == params[:month] && day == params[:day]
			@tomorrow_bool = true
		end


		if @tomorrow_bool
			@away_pitchers = Pitcher.where(:game_id => nil, :team_id => @away_team.id, :tomorrow_starter => true).first
			@home_pitchers = Pitcher.where(:game_id => nil, :team_id => @home_team.id, :tomorrow_starter => true).first
			@away_bullpen_pitchers = Array.new
			@home_bullpen_pitchers = Array.new
		else
			@away_pitchers = Pitcher.where(:game_id => @game.id, :team_id => @away_team.id, :starter => true).first
			@home_pitchers = Pitcher.where(:game_id => @game.id, :team_id => @home_team.id, :starter => true).first
			@away_bullpen_pitchers = Pitcher.where(:game_id => @game.id, :team_id => @away_team.id, :bullpen => true)
			@home_bullpen_pitchers = Pitcher.where(:game_id => @game.id, :team_id => @home_team.id, :bullpen => true)
		end

		if @away_pitchers != nil
			if @away_pitchers.throwhand == 'L'
				@home_left = true
			else
				@home_left = false
			end
		end

		if @home_pitchers != nil
			if @home_pitchers.throwhand == 'L'
				@away_left = true
			else
				@away_left = false
			end
		end

		@month = Date::MONTHNAMES[@game.month.to_i]
		day = @game.day.to_i.to_s
		@date = @month + ' ' + day
		day = Date.parse("#{params[:year]}-#{params[:month]}-#{params[:day]}").wday
		@one = Date::DAYNAMES[day-1]
		@two = Date::DAYNAMES[day-2]
		@three = Date::DAYNAMES[day-3]



		if !@tomorrow_bool

			@away_hitters = Hitter.where(:game_id => @game.id, :team_id => @away_team.id, :starter => true).order("lineup")
			@home_hitters = Hitter.where(:game_id => @game.id, :team_id => @home_team.id, :starter => true).order("lineup")

		else

			@away_hitters = Array.new
			@home_hitters = Array.new

		end

		@away_projected = false
		@home_projected = false

		if today_bool || @tomorrow_bool

			if @away_hitters.size == 0
				@away_hitters = findProjectedLineup(@game, false, @away_pitchers, @home_pitchers)
				@away_hitters = getCurrentStats(@away_hitters)
				@away_projected = true
			end

			if @home_hitters.size == 0
				@home_hitters = findProjectedLineup(@game, true, @away_pitchers, @home_pitchers)
				@home_hitters = getCurrentStats(@home_hitters)
				@home_projected = true
			end

		end

		if !@away_hitters.empty?
			away_total = addTotalStats(@away_hitters)
			@away_hitters << away_total
		end
		if !@home_hitters.empty?
			home_total = addTotalStats(@home_hitters)
			@home_hitters << home_total
		end
		

	end


	def team
		@team = Team.find_by_id(params[:id])
		if params[:left] == '1'
			@left = true
		else
			@left = false
		end

		if @left
			@pitchers = @team.pitchers.where(:game_id => nil).order(:IP_L).reverse
			@hitters = @team.hitters.where(:game_id => nil).order(:AB_L).reverse
		else
			@pitchers = @team.pitchers.where(:game_id => nil).order(:IP_R).reverse
			@hitters = @team.hitters.where(:game_id => nil).order(:AB_R).reverse.limit(20)
		end
	end

end
