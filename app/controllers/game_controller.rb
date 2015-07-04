class GameController < ApplicationController

	def matchup
		require 'date'

		year = Time.now.tomorrow.year.to_s
		month = Time.now.tomorrow.month.to_s
		day = Time.now.tomorrow.day.to_s


		if year == params[:year] && month == params[:month] && day == params[:day]
			redirect_to(:action => 'tomorrow', :id => params[:id], :year => params[:year], :month => params[:month], :day => params[:day])
		end

		if params[:left] == '1'
			@left = true
		else
			@left = false
		end

		@game = Game.find_by_id(params[:id])
		@home = @game.home_team
		@away = @game.away_team
		@month = Date::MONTHNAMES[@game.month.to_i]
		@away_hitters = Hitter.where(:game_id => @game.id, :team_id => @away.id, :starter => true).order("lineup")
		@home_hitters = Hitter.where(:game_id => @game.id, :team_id => @home.id, :starter => true).order("lineup")

		today = Time.now
		@home_projected = false
		@away_projected = false
		if @game.year.to_i == today.year && @game.month.to_i == today.month && @game.day.to_i == today.day

			if @away_hitters.empty?
				@away_hitters = findProjectedLineup(@game, false)
				@away_hitters = getCurrentStats(@away_hitters)
				@away_projected = true
			end

			if @home_hitters.empty?
				@home_hitters = findProjectedLineup(@game, true)
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
		
		@away_pitchers = Pitcher.where(:game_id => @game.id, :team_id => @away.id, :starter => true)
		@home_pitchers = Pitcher.where(:game_id => @game.id, :team_id => @home.id, :starter => true)
		@away_bullpen_pitchers = Pitcher.where(:game_id => @game.id, :team_id => @away.id, :bullpen => true)
		@home_bullpen_pitchers = Pitcher.where(:game_id => @game.id, :team_id => @home.id, :bullpen => true)

		day = @game.day.to_i.to_s
		@date = @month + ' ' + day
		day = Date.parse("#{params[:year]}-#{params[:month]}-#{params[:day]}").wday
		@one = Date::DAYNAMES[day-1]
		@two = Date::DAYNAMES[day-2]
		@three = Date::DAYNAMES[day-3]

	end

	def tomorrow
		@game = Game.find_by_id(params[:id])
		@home = @game.home_team
		@away = @game.away_team
		@away_pitchers = Pitcher.where(:game_id => nil, :team_id => @away.id, :tomorrow_starter => true)
		@home_pitchers = Pitcher.where(:game_id => nil, :team_id => @home.id, :tomorrow_starter => true)
		month = Date::MONTHNAMES[@game.month.to_i]
		day = @game.day.to_i.to_s
		@date = month + ' ' + day
	end

end
