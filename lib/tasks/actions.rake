namespace :houston do
  desc "Lists actions"
  task :actions do
    actions = Houston.actions.to_a
    longest_name = actions.map { |action| action.name.length }.max
    longest_params = actions.map { |action| action.required_params.join(", ").length }.max
    actions.sort_by(&:name).each do |action|
      params = "#{action.required_params.join(", ")}" if action.required_params.any?
      puts "  \e[36m#{action.name.ljust(longest_name)}\e[0m  \e[96m#{params.to_s.ljust(longest_params)}\e[0m"
    end
  end
end
