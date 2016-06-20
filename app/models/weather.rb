class Weather < ActiveRecord::Base
  belongs_to :game

  def temp_num
    return 0.0 if temp.size == 0
    index = temp.index(".")
    index ? temp[0..index+1].to_f : temp[0..1].to_f
  end

  def dew_num
    return 0.0 if temp.size == 0
    index = dew.index(".")
    index ? dew[0..index+1].to_f : dew[0..1].to_f
  end

  def humid_num
    return 0.0 if humidity.size == 0
    humidity[0..1].to_f
  end

  def baro_num
    pressure.include?(".") ? (pressure[0...-3].to_i * 33.86375257787817).round(2) : 0.0
  end

  def air_density
    unless baro_num == 0.0 || dew_num == 0.0 || temp_num == 0.0
      Create::AirDensity.new.run(baro_num, temp_num, dew_num)
    else
      0.0
    end
  end
end
