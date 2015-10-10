require "test_helper"

class SourceFileCoverageTest < ActiveSupport::TestCase


  # https://github.com/colszowka/simplecov/blob/v0.7.1/test/test_source_file.rb
  test "SourceFileCoverage should pass SimpleCov::SourceFile's specs" do
    project = Project.new(name: "Test", slug: "test", version_control_name: "Mock")
    test_run = TestRun.new(project: project, sha: "bd3e9e2", coverage: [
      { filename: "test.rb", coverage: [nil, 1, 1, 1, nil, nil, 1, 0, nil, nil, nil, nil, nil, nil, nil, nil] }
    ])

    mock(project).read_file("test.rb", commit: "bd3e9e2") do
      File.read(Rails.root.join("test", "fixtures", "simplecov_sample.rb"))
    end

    @source_file = test_run.coverage_detail.first

    assert @source_file.filename, "should have a filename"
    assert_equal @source_file.source, @source_file.src, "should have source equal to src"
    assert_equal @source_file.source_lines, @source_file.lines, "should have source_lines equal to lines"
    assert_equal 16, @source_file.lines.count, "should have 16 source lines"
    assert @source_file.lines.all? {|l| l.instance_of?(SimpleCov::SourceFile::Line)}, "should have all source lines of type SimpleCov::SourceFile::Line"
    assert_equal "class Foo\n", @source_file.line(2).source, "should have 'class Foo' as line(2).source"
    assert_equal [2, 3, 4, 7], @source_file.covered_lines.map(&:line), "should return lines number 2, 3, 4, 7 for covered_lines"
    assert_equal [8], @source_file.missed_lines.map(&:line), "should return lines number 8 for missed_lines"
    assert_equal [1, 5, 6, 9, 10, 11, 15, 16], @source_file.never_lines.map(&:line), "should return lines number 1, 5, 6, 9, 10, 11, 15, 16 for never_lines"
    assert_equal [12, 13, 14], @source_file.skipped_lines.map(&:line), "should return line numbers 12, 13, 14 for skipped_lines"
    assert_equal 80.0, @source_file.covered_percent, "should have 80% covered_percent"
  end


end
