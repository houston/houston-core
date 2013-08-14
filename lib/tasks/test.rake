require 'rbconfig'
require 'rake/testtask'

namespace :test do
  Rake::TestTask.new(:all => "test:prepare") do |t|
    t.libs << "test"
    t.test_files = %w{unit functional integration}.map { |dir| Dir.glob("test/#{dir}/**/*_test.rb") }.flatten
  end
end
