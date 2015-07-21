namespace :test do
	
	task :test => :environment do

		nil_hitters = Hitter.where(:game_id => nil)
		nil_pitchers = Pitcher.where(:game_id => nil)

		nil_pitchers.each do |pitcher|
			id = pitcher.fangraph_id
			if id == nil || id == 0
				if pitcher.alias != "" || pitcher.alias != nil
					hitter = nil_hitters.find_by_alias(pitcher.alias)
					if hitter == nil
						puts pitcher.nam
					end
					pitcher.update_attributes(:fangraph_id => hitter.fangraph_id)
				end
			end
		end

	end

end