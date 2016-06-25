module Houston
  module Props
    extend ActiveSupport::Concern

    VALID_PROP_NAME = /\A[a-z0-9]+(?:\.[a-z0-9]+)+\Z/i.freeze

    def self.valid_prop_name!(prop_name)
      return if prop_name =~ VALID_PROP_NAME
      raise ArgumentError, "#{prop_name.inspect} can only contain letters, numbers, and must contain at least one period"
    end


    module ClassMethods
      def find_by_prop(prop_name, value)
        Houston::Props.valid_prop_name!(prop_name)
        result = where(["props->>'#{prop_name}' = ?", value]).limit(1).first

        if !result && block_given?
          result = yield value
          if result
            result.update_prop! prop_name, value
          else
            Rails.logger.info "\e[34mUnable to identify a #{name} where \e[1m#{prop_name}\e[0;34m=\e[1m#{value}\e[0m"
          end
        end

        result
      end
    end


    def get_prop(prop_name)
      Houston::Props.valid_prop_name!(prop_name)
      value = props[prop_name]

      if !value && block_given?
        value = yield self
        if value
          update_prop! prop_name, value
        else
          Rails.logger.info "\e[34mUnable to identify \e[1m#{prop_name}\e[0;34m for #{inspect}\e[0m"
        end
      end

      value
    end

    def update_prop!(prop_name, value)
      update_column :props, props.merge!(prop_name => value)
    end

    def props
      PropsIndexer.new(self, super)
    end

  private

    class PropsIndexer
      def initialize(record, hash)
        @record = record
        @hash = hash
      end

      def [](prop_name)
        @hash[prop_name]
      end

      def fetch(prop_name, default_value)
        @hash.fetch(prop_name, default_value)
      end

      def []=(prop_name, value)
        merge!(prop_name => value)
      end

      def merge!(new_props)
        new_props.each_key(&Houston::Props.method(:valid_prop_name!))
        @record.props = @hash = @hash.merge(new_props)
      end

      def delete!(key)
        @record.props = @hash = @hash.except(key)
      end

      def to_h
        @hash.dup
      end
    end

  end
end
