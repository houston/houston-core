class PersistentTrigger < ActiveRecord::Base
  self.inheritance_column = nil

  serialize :value, Houston::Serializer.new
  serialize :params, Houston::ParamsSerializer.new

  TYPES = [:at, :on, :every].freeze
  validates :type, inclusion: { in: TYPES, message: "{value} is not valid Trigger type; use #{TYPES.map(&:inspect).to_sentence(two_words_connector: " or ", last_word_connector: ", or ")}" }
  validate :action_must_be_defined

  after_create :register!


  TYPES.each do |type|
    instance_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{type}(value, action, params={})
        self.new(type: :#{type}, value: value, action: action, params: params)
      end
    RUBY
  end


  def self.load_all
    all.find_each(&:register!)
  end


  def type
    super && super.to_sym
  end


  def register!
    trigger = Houston.config.triggers.build(type, value, action, params)
    Houston.config.triggers.push(trigger) unless Houston.config.triggers.member?(trigger)
  end


private

  def action_must_be_defined
    return if Houston.config.actions.exists?(action)
    errors.add :action, "#{action.inspect} is not defined"
  end

end
