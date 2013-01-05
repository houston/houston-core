Houston.observer.on "testing_note:save" do |testing_note|
  if testing_note.verdict == "fails"
    ProjectNotification.failing_verdict(testing_note).deliver!
  end
end
