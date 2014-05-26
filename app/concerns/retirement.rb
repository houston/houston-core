module Retirement
  extend ActiveSupport::Concern
  
  module ClassMethods
    def unretired
      where(retired_at: nil)
    end
    
    def retired
      where(arel_table[:retired_at].not_eq(nil))
    end
  end
  
  
  def retire!
    update_column(:retired_at, Time.now)
    freeze
  end
  
  def unretire!
    update_column(:retired_at, nil)
  end
  
  def retired?
    retired_at.present?
  end
  
end
