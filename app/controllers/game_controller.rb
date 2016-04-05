class GameController < ApplicationController
	include Share
	require 'date'

	def matchup

		@game = Game.find_by_id(params[:id])
		@away_team = @game.away_team
		@home_team = @game.home_team

		# Set the boxscores and innings of the game if information is available
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

		@today_bool = game_day?(Time.now)
		@tomorrow_bool = game_day?(Time.now.tomorrow)

		if @tomorrow_bool
			@away_pitcher = Pitcher.where(:game_id => nil, :team_id => @away_team.id, :tomorrow_starter => true).first
			@home_pitcher = Pitcher.where(:game_id => nil, :team_id => @home_team.id, :tomorrow_starter => true).first
			@away_bullpen_pitchers = Array.new
			@home_bullpen_pitchers = Array.new
		else
			@away_pitcher = Pitcher.where(:game_id => @game.id, :team_id => @away_team.id, :starter => true).first
			@home_pitcher = Pitcher.where(:game_id => @game.id, :team_id => @home_team.id, :starter => true).first
			@away_bullpen_pitchers = Pitcher.where(:game_id => @game.id, :team_id => @away_team.id, :bullpen => true).order("one").order("two").order("three").order("four").order("five")
			@home_bullpen_pitchers = Pitcher.where(:game_id => @game.id, :team_id => @home_team.id, :bullpen => true).order("one").order("two").order("three").order("four").order("five")
		end

		# Set the left variable depending on whether the opposing pitcher is a lefty
		if @away_pitcher
			@home_left = lefty?(@away_pitcher.throwhand)
		end

		if @home_pitcher
			@away_left = lefty?(@home_pitcher.throwhand)
		end

		# Set the date variables needed for the bullpen
		@month = Date::MONTHNAMES[@game.month.to_i]
		day = @game.day.to_i.to_s
		@date = @month + ' ' + day
		day = Date.parse("#{params[:year]}-#{params[:month]}-#{params[:day]}").wday
		@one = Date::DAYNAMES[day-1]
		@two = Date::DAYNAMES[day-2]
		@three = Date::DAYNAMES[day-3]
		@four = Date::DAYNAMES[day-4]
		@five = Date::DAYNAMES[day-5]

		# Set the hitters variable unless this is tomorrow's game
		unless @tomorrow_bool
			@away_starting_hitters = Hitter.where(:game_id => @game.id, :team_id => @away_team.id, :starter => true).order("lineup")
			@home_starting_hitters = Hitter.where(:game_id => @game.id, :team_id => @home_team.id, :starter => true).order("lineup")
		else
			@away_starting_hitters = Array.new
			@home_starting_hitters = Array.new
		end



		# Determine whether or not we need to project the lineup
		@away_projected = false
		@home_projected = false

		if @today_bool || @tomorrow_bool
			if @away_starting_hitters.empty?
				@away_starting_hitters = find_projected_lineup(@game, @away_team, @home_pitcher)
				unless @away_starting_hitters.empty?
					@away_starting_hitters = get_current_stats(@away_starting_hitters)
					@away_projected = true
				end
			end

			if @home_starting_hitters.empty?
				@home_starting_hitters = find_projected_lineup(@game, @home_team, @away_pitcher)
				unless @home_starting_hitters.empty?
					@home_starting_hitters = get_current_stats(@home_starting_hitters)
					@home_projected = true
				end
			end
		end

		# calculate the number of hitters facing the pitcher with the same handedness
		@away_pitcher_same = @away_pitcher_diff = 0
		if @away_pitcher && @home_starting_hitters.size == 9
			@home_starting_hitters.each do |hitter|
				if hitter.bathand == @away_pitcher.throwhand
					@away_pitcher_same += 1
				end
			end
			@away_pitcher_diff = 9 - @away_pitcher_same
		end

		@home_pitcher_same = @home_pitcher_diff = 0
		if @home_pitcher && @away_starting_hitters.size == 9
			@away_starting_hitters.each do |hitter|
				if hitter.bathand == @home_pitcher.throwhand
					@home_pitcher_same += 1
				end
			end
			@home_pitcher_diff = 9 - @home_pitcher_same
		end

		# Add the stats of each lineup and add a total column to the array

		# render text: @home_starting_hitters[]
		unless @away_projected
			unless @away_starting_hitters.empty?
				away_total = add_total_stats(@away_starting_hitters)
				@away_starting_hitters << away_total
			end
		end

		unless @home_projected
			unless @home_starting_hitters.empty?
				home_total = add_total_stats(@home_starting_hitters)
				@home_starting_hitters << home_total
			end
		end
		@away_bench_hitters = Hitter.where(:game_id => nil, :team_id => @away_team.id, :starter => false).order(AB_R: :desc)
		@home_bench_hitters = Hitter.where(:game_id => nil, :team_id => @home_team.id, :starter => false).order(AB_R: :desc)
		

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

  def game_day?(time)
  	hour, day, month, year = find_date(time)
  	if year.to_i == params[:year].to_i && month.to_i == params[:month].to_i && day.to_i == params[:day].to_i
  	  true
  	else
  	  false
  	end
  end

  def lefty?(throwhand)
  	if throwhand == 'L'
	  true
	else
	  false
	end
  end

end
