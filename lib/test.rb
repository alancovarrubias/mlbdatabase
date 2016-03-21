module Test

	def self.boo
		puts "boo"
	end

	def self.whoo
		puts "whoo"
		self.boo
	end

end