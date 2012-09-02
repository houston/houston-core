module DemoHelper
  
  def random_ticket_age # in seconds
    case rand(3)
    when 0; rand(3.hours)
    when 1; rand(3.weeks)
    when 2; rand(3.months)
    end
  end
  
  def random_ticket_number
    rand(5000) + 1
  end
  
  def random_density
    case rand(5)
    when 0..1; 4
    when 2..3; 16
    when 4; 64
    end
  end
  
end
