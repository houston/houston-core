class TesterPresenter
  
  def initialize(testers)
    @testers = testers
  end
  
  def as_json(*args)
    @testers.map do |tester|
      { id: tester.id,
        name: tester.name,
        email: tester.email }
    end
  end
  
end
