require "bundler/gem_tasks"
require "rubocop/rake_task"
RuboCop::RakeTask.new

begin
  targeted_files = ARGV.drop(1)
  file_pattern = targeted_files.empty? ? "spec/**/*_spec.rb" : targeted_files

  require "rspec/core"
  require "rspec/core/rake_task"

  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = FileList[file_pattern]
  end

  RSpec.configure do |config|
    config.color = true
    config.formatter = :documentation
  end
rescue LoadError
  require "spec/rake/spectask"

  puts file_pattern

  Spec::Rake::SpecTask.new(:spec) do |t|
    t.pattern = FileList[file_pattern]
    t.spec_opts += ["--color"]
  end
end
