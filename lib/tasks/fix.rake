namespace :fix do

  require 'nokogiri'
  require 'open-uri'

  task :test => :environment do
  	url = "https://www.wunderground.com/us/wi/milwaukee/zmw:53214.1.99999"
  	doc = Nokogiri::HTML(open(url))
  	doc.css("td").each do |stat|
  	  puts stat
  	end
  end

end