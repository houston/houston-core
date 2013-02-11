Houston.observer.on "testing_note:save" do |testing_note|
  unless testing_note.verdict == "works"
    ProjectNotification.testing_note(testing_note).deliver!
  end
end
