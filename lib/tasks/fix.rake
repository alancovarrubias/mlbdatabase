namespace :fix do
	
  require 'nokogiri'
  require 'open-uri'
  require 'timeout'
  task :test => :environment do
    Game.all.each do |game|
      puts game.url
      game.hitters.each do |player|
      	
      end
    end	
  end

end