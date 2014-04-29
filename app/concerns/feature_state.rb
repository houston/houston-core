module FeatureState
  
  def feature_broken!(feature_name)
    set_feature_state! feature_name, "broken"
  end
  
  def feature_working!(feature_name)
    set_feature_state! feature_name, "working"
  end
  
  def feature_state(feature_name)
    feature_states[feature_name.to_s]
  end
  
  def broken_features(*features)
    features.flatten.select { |feature_name| feature_state(feature_name) == "broken" }
  end
  
  def feature_states
    super || {}
  end
  
  def set_feature_state!(feature_name, state)
    update_column :feature_states, feature_states.merge(feature_name.to_s => state)
  end
  
end
