namespace :test do
	
	task :test => :environment do
		require 'nokogiri'
		require 'open-uri'

		url = "http://www.fangraphs.com/depthcharts.aspx?position=ALL&teamid=1"
		doc = Nokogiri::HTML(open(url))

		doc.css(".depth_chart:nth-child(76) td").each_with_index do |stat, index|
			case index%10
			when 0

				name = stat.child.child
				# name = stat.text
				# while !letter?(name[-1])
				# 	name = name[0...-1]
				# end
				# fangraph_id = getFangraph(stat)
				# if hitter = hitters.find_by_name(name)
				# 	hitter.update_attributes(:fangraph_id => fangraph_id)
				# elsif hitter = hitters.find_by_name(nicknames[name])
				# 	hitter.update_attributes(:fangraph_id => fangraph_id)
				# else
				# 	if name != 'Total'
				# 		puts name + ' not found'
				# 	end
				# end
			end
		end

	end

end