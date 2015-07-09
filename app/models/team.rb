class Team < ActiveRecord::Base
	has_many :pitchers
	has_many :hitters

	def fangraph_abbr
		name = self.name
		if name.include?(" ")
			index = name.index(" ")
			return name[0...index] + "%20" + name[index+1..-1]
		end
		return name
	end
end
