module Update
  class Games

  	include NewShare

  	def update(game_day)
  		closingline(game_day)
	  	unless game_day == GameDay.search(Time.now)
	  		return
	  	end
	  	umpire(game_day)
  	end

  	private

  end
end