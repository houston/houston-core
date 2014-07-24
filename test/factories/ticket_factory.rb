FactoryGirl.define do
  factory :ticket do
    project
    type "Bug"
    number 1
    summary "Test summary"
  end
end
