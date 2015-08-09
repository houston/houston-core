FactoryGirl.define do
  factory :commit do
    message "[skip] Generated this commit with FactoryGirl"
    committer "Factory Girl"
    committer_email "factorygirl@thoughtbot.com"
    authored_at { Time.now }
    sha { SecureRandom.hex(20) }
  end
end
