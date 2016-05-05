module Update

	class Intellicast

		include NewShare

		attr_accessor :game_day

		def initialize(game_day)
			@game_day = game_day
		end

		def update
			unless valid_game_day?
				return
			end

			game_day.games.each do |game|
				doc = download_document(get_url(game))
				
			end
		end


		private

		  def valid_game_day?
		  	game_day == GameDay.search(Time.now)
		  end

		  def get_url(game)
		  	@@urls[game.home_team_id - 1]
		  end

	end
end