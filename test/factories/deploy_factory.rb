FactoryGirl.define do
  factory :deploy do
    environment_name "production"
    sha "edd44727c05c93b34737cb48873929fb5af69885"
    completed_at { Time.now }
  end
end
