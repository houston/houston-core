Houston.config.every "3h", "cache:key-dependencies" do
  CacheKeyDependencies.for Project.unretired
end
