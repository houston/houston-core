require 'resque/tasks'

# Load Houston's Rails environment for every worker
task "resque:setup" => :environment do
end
