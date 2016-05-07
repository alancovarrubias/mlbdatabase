class TestClass

  def initialize
    @var = 1
  end

  def set
    @var = 1
  end

  def self.main
    puts @var
  end

  def main
    puts @var
  end

end

puts TestClass.new.instance_variables