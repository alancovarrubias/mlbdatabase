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

	def gethandedstat(handedness, same, diff, left_stat, right_stat)
		if same + diff == 9
			if handedness == "L"
				((same * left_stat + diff * right_stat)/9).round(2)
			elsif handedness == "R"
				((same * right_stat + diff * left_stat)/9).round(2)
			else
				0
			end
		else
			0
		end
	end

end
