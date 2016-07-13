require "oj_serializer"

Oj.register_odd(Date, Date, :iso8601, :iso8601)
Oj.register_odd(DateTime, DateTime, :iso8601, :iso8601)

class OjSerializer
  def load(string)
    Oj.load string, nilnil: true, auto_define: false
  end

  def dump(object)
    Oj.dump object
  end
end
