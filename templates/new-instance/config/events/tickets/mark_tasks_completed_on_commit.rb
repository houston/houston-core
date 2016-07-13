# Treat tasks as completed when a commit mentioning them is pushed

Houston.config do
  on "task:committed" => "task:mark-completed" do
    task.completed!
  end
end
