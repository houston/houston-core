FactoryGirl.define do
  factory :user do
    first_name "Bob"
    last_name "Lail"
    email "bob.lail@houston.test"
    password "password"
    password_confirmation "password"
  end
end
