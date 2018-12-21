class PersistentTrigger < ActiveRecord::Base
  self.inheritance_column = nil

  serialize :value, Houston::Serializer.new
  serialize :params, Houston::ParamsSerializer.new

  belongs_to :user

  TYPES = [:on, :every].freeze

  validates :user_id, presence: true
  validates :type, inclusion: { in: TYPES, message: "{value} is not valid Trigger type; use #{TYPES.map(&:inspect).to_sentence(two_words_connector: " or ", last_word_connector: ", or ")}" }
  validate :action_must_be_defined

  after_create :register!
  after_destroy :unregister!


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
    return if registered_trigger
    @registered_trigger = Houston.config.triggers.create(type, value, action, params.merge(trigger: self), persistent_trigger_id: id)
  end

  def unregister!
    return unless registered_trigger
    Houston.config.triggers.delete(registered_trigger)
  end


private

  def action_must_be_defined
    return if Houston.config.actions.exists?(action)
    errors.add :action, "#{action.inspect} is not defined"
  end

  def registered_trigger
    @registered_trigger ||= Houston.config.triggers.detect { |trigger| trigger.persistent_trigger_id == id }
  end

end
