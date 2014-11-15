require "test_helper"


class TicketTasksApiTest < ActionDispatch::IntegrationTest
  attr_reader :project, :ticket
  
  setup do
    @project = create(:project)
    @ticket = create(:ticket, project: project)
    @task1 = @ticket.tasks.first
    @task1.update_attributes!(description: "Step 1", effort: 3)
    @task2 = @ticket.tasks.create!(description: "Step 2", effort: 7)
  end
  
  
  context "GET /api/v1/projects/SLUG/tickets/by_number/NUMBER/tasks" do
    should "return 401 if I'm not authenticated" do
      get tasks_path
      assert_response :unauthorized
    end
    
    
    should "return a list of the tickets's tasks" do
      get tasks_path, {}, env
      assert_response :success
      
      expected_tasks = [
        { "id" => @task1.id, "number" => 1, "letter" => "a", "description" => "Step 1",
          "effort" => "3.0", "committedAt" => nil, "releasedAt" => nil, "completedAt" => nil },
        { "id" => @task2.id, "number" => 2, "letter" => "b", "description" => "Step 2",
          "effort" => "7.0", "committedAt" => nil, "releasedAt" => nil, "completedAt" => nil }
      ]
      
      response_json = MultiJson.load(response.body)
      assert_equal expected_tasks, response_json,
        "Expected the API to have responded with the expected list of tasks"
    end
  end
  
  
  context "POST /api/v1/projects/SLUG/tickets/by_number/NUMBER/tasks" do
    should "respond with validation effors if description is omitted" do
      expected_response = MultiJson.dump(errors: ["Description can't be blank"])
      
      post tasks_path, {effort: 2.1}, env
      assert_response :unprocessable_entity
      assert_equal expected_response, response.body,
        "Expected the API to have responded with the appropriate error message"
    end
    
    should "add a new task to the ticket" do
      post tasks_path, {description: "Step 3", effort: 2.1}, env
      assert_response :created
      assert_equal [3, "Step 3", BigDecimal.new("2.1")], ticket.tasks.pluck(:number, :description, :effort).last,
        "Expected to find that the third task has been created"
    end
  end
  
  
private
  
  def tasks_path
    "api/v1/projects/#{project.slug}/tickets/by_number/#{ticket.number}/tasks"
  end
  
  def env
    { "HTTP_AUTHORIZATION" => "Basic " + Base64::encode64("bob@example.com:password") }
  end
  
end
