require "thread_safe"
require "ostruct"

module Houston
  
  def self.tdl
    @tdl ||= Tdl.new
  end
  
  
  
  class Tdl
    
    def initialize
      @array = ThreadSafe::Array.new
    end
    
    def add(attributes)
      Houston::Tdl::Task.new(attributes).tap do |task|
        @array.push(task)
      end
    end
    
    def remove(task)
      @array.delete task
    end
    
    def empty?
      @array.empty?
    end
    
    def map(&block)
      @array.map(&block)
    end
    
    def where(attributes)
      @array.select { |task| attributes.all? { |key, value| task.public_send(key) == value } }
    end
    
    
    
    class Task
      attr_reader :goal, :step, :description, :conversation
      
      def initialize(new_attributes)
        @attributes = ThreadSafe::Hash.new
        @goal = new_attributes.fetch :goal
        @description = new_attributes.fetch :describe
        @conversation = new_attributes.fetch :conversation, nil
        
        set! new_attributes.reverse_merge(advisory: nil)
      end
      
      def describe
        [description, advisory].compact.join(" ")
      end
      
      def end!(*messages)
        conversation.reply(*messages) if conversation && messages.any?
        conversation.end! if conversation
        Houston.tdl.remove self
        self
      end
      alias :cancel! :end!
      
      def advise(advisory)
        set! advisory: advisory
      end
      
      def set!(new_attributes)
        attributes.merge! new_attributes.except(*PROTECTED_ATTRIBUTES)
        set_step! new_attributes[:step] if new_attributes.key? :step
      end
      
      def respond_to_missing?(key, include_all)
        return true if attributes.key?(key)
      end
      
      def [](key)
        value = attributes[key]
        value = OpenStruct.new(value) if value.is_a?(Hash)
        value
      end
      
      def method_missing(key, *args)
        self[key]
      end
      
    private
      attr_reader :attributes
      
      def set_step!(step)
        unless @step == step
          @step = step
          Rails.logger.debug "\e[34m[tdl] Working on tdl:#{goal}.#{step}\e[0m"
          Houston.observer.fire "tdl:#{goal}.#{step}", self
        end
      end
      
      PROTECTED_ATTRIBUTES = [:goal, :describe, :step, :conversation].freeze
    end
    
  end
end
