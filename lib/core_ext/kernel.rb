module Kernel

  def exceptions_wrapping(error_class)
    m = Module.new
    (class << m; self; end).instance_eval do
      define_method(:===) do |err|
        err.respond_to?(:original_exception) && error_class === err.original_exception
      end
    end
    m
  end

  def exceptions_matching(matcher)
    m = Module.new
    (class << m; self; end).instance_eval do
      define_method(:===) do |err|
        err.message =~ matcher
      end
    end
    m
  end

end
