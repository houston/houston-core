class TicketTag

  def initialize(name, color)
    @name = name
    @color = color
  end

  attr_reader :name, :color

  def self.from_s(string)
    name, color = string.scan(/\[([^\]]+)\]\(([a-fA-F0-9]{6})\)/).flatten
    name = string unless name
    color = "e4e4e4" unless color
    new(name, color)
  end

  def to_s
    "[#{name}](#{color})"
  end

  def to_h
    {name: name, color: color}
  end

end
