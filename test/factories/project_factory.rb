FactoryGirl.define do
  factory :project do
    team { Team.first }
    name "Test"
    slug "test"
  end
end
