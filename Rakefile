require 'rake/testtask'

task :default => "test:all"

namespace :test do
  desc "Run all test suites"
  task :all => [:unit, :acceptance]

  Rake::TestTask.new(:unit) do |t|
    t.libs << "test" << "lib"
    t.pattern = "#{File.dirname(__FILE__)}/test/unit/**/*_test.rb"
  end

  Rake::TestTask.new(:acceptance) do |t|
    t.libs << "test" << "lib"
    t.pattern = "#{File.dirname(__FILE__)}/test/acceptance/**/*_test.rb"
  end
end
