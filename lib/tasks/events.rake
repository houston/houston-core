namespace :houston do
  desc "Lists registered events and their descriptions"
  task :events do
    longest_name = Houston.events.map { |event| event.name.length }.max
    longest_params = Houston.events.map { |event| event.params.join(", ").length }.max
    Houston.events.sort_by(&:name).each do |event|
      params = "#{event.params.join(", ")}" if event.params.any?
      puts "  \e[36m#{event.name.ljust(longest_name)}\e[0m  \e[96m#{params.to_s.ljust(longest_params)}\e[0m  #{event.description}"
    end
  end
end
