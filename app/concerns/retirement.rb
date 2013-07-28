module Retirement
  extend ActiveSupport::Concern
  
  included do
    default_scope where(retired_at: nil)
  end
  
  
  
  module ClassMethods
    
    def with_retired
      unscoped
    end
    
    def retired
      with_retired.where(arel_table[:retired_at].not_eq(nil))
    end
    
  end
  
  
  
  def retire!
    update_column(:retired_at, Time.now)
    freeze
  end
  
  def unretire!
    update_column(:retired_at, nil)
  end
  
end
