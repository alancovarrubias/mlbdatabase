class Weather < ActiveRecord::Base
  belongs_to :game

  def temp_num
    index = temp.index(".")
    index ? temp[0..temp.index(".")+1].to_f : 0.0
  end

  def dew_num
    index = dew.index(".")
    index ? dew[0..dew.index(".")+1].to_f : 0.0
  end

  def baro_num
    pressure.include?(".") ? (pressure[0...-3].to_i * 33.86375257787817).round(2) : 0.0
  end

  def air_density
    unless baro_num == 0.0 || dew_num == 0.0 || temp_num == 0.0
      Create::AirDensity.new.run(baro_num, temp_num, dew_num)
    end
  end
end
