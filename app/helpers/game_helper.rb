module GameHelper

	def format_time(time, plus)

		original_hour = time[0...time.index(":")].to_i
		suffix = time[-2..-1]
		hour = original_hour + plus

		if hour >= 12 && original_hour < 12
			if suffix == "PM"
				suffix = "AM"
			else
				suffix = "PM"
			end
		end

		if hour > 12
			hour = hour - 12
		end

		return hour.to_s + ":00 " + suffix

	end

end
