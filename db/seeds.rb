# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
include PlayerUpdate

(2014..2016).each do |i|
  Season.create(year: i)
end

Season.all.each do |season|
  Team.all.each do |team|
  	create_players(season, team)
  end
end

