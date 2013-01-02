Houston.observer.on "testing_note:save" do |testing_note|
  if testing_note.verdict == "fails"
    ProjectMailer.notice_of_failing_verdict(testing_note).deliver!
  end
end
