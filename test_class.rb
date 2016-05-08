class TestClass

  def set
    @var = Array.new
    checkit
    puts @var.size
  end

  def checkit
    @var << 1
    puts @var.size
  end

end

# TestClass.main
TestClass.new.set