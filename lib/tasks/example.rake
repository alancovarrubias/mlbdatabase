namespace :example do
	
	require 'nokogiri'
	require 'open-uri'
	require 'timeout'
	task :test => :environment do
		puts Time.now.hour
	end

end