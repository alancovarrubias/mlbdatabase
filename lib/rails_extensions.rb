class Array

  def add_ip
  	sum = 0
  	each do |element|
  	  sum += element
  	end
  	sum
  end

end

class String
  def to_magic
  	"magic"
  end
end