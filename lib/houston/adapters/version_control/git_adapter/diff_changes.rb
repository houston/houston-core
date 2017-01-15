require "delegate"

class DiffChange < Struct.new(:type, :file)
  def added?
    type == "A"
  end

  def copied?
    type == "C"
  end

  def deleted?
    type == "D"
  end

  def modified?
    type == "M"
  end

  def renamed?
    type == "R"
  end

  def type_changed?
    type == "T"
  end

  def unmerged?
    type == "U"
  end

  def broken?
    type == "B"
  end
end

class DiffChanges < SimpleDelegator
  def initialize(diff)
    super diff.to_s.scan(/^([^\t]+)\t(.*)$/).map { |(type, file)| DiffChange.new(type, file) }
  end

  def grep(regex)
    __getobj__.select { |change| change.file =~ regex }
  end

  def [](filename)
    __getobj__.detect { |change| change.file == filename }
  end
end
