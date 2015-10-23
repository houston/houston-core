def weekend?(time)
  [0, 6].member?(time.wday)
end

def monday_after(time)
  8.hours.after(1.week.after(time.beginning_of_week))
end
