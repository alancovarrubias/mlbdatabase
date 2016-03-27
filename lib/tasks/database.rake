namespace :database do

	task :count => :environment do
		Team.get_class_variable
	end
	
end