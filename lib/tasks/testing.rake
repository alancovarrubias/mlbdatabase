namespace :testing do

	task :test => :environment do
		unless nil
			print "nil"
		end
		if [].empty?
			print "empty"
		end
	end


end