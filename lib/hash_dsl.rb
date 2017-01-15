class HashDsl
  attr_reader :hash
  alias :to_hash :hash
  alias :to_h :hash

  def initialize
    @hash = {}
  end

  def self.from_block(block)
    HashDsl.new.tap { |dsl| dsl.instance_eval(&block) }
  end

  def self.hash_from_block(block)
    from_block(block).to_hash
  end

  def method_missing(method_name, *args, &block)
    if block_given?
      @hash[method_name] = HashDsl.hash_from_block(block)
    elsif args.length == 1
      @hash[method_name] = args.first
    else
      super
    end
  end
end
