# Treat tasks as completed when a commit mentioning them is pushed

Houston.config do
  on "task:committed" do |e|
    e.task.completed!
  end
end
