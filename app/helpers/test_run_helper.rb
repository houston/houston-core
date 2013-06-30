module TestRunHelper
  
  def test_status(test)
    return "pass" if test[:status] == :pass
    "fail" # may be :fail or :regresion
  end
  
end
