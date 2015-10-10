module ExcelHelpers

  def xls_time(time)
    time.strftime "%Y-%m-%dT%H:%M:%S"
  end

end
