namespace :houston do
  desc "Lists actions"
  task :actions => :environment do
    longest_name = Houston.actions.names.map(&:length).max
    Houston.actions.names.sort.each do |name|
      puts "  \e[36m#{name.ljust(longest_name)}\e[0m"
    end
  end
end
