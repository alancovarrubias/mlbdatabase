namespace :fix do
	
  require 'nokogiri'
  require 'open-uri'
  require 'timeout'
  task :test => :environment do
    include Update
    team = Team.first
    update_pitchers_ops(team, "2015")
  end

end