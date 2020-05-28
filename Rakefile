require 'rubygems'
require 'rspec'
require 'rspec/core/rake_task'
require 'bundler/gem_tasks'
require 'yard'

namespace :gem do
  desc "Build the spira-#{File.read('VERSION').chomp}.gem file"
  task :build do
    sh "gem build spira.gemspec && mv spira-#{File.read('VERSION').chomp}.gem pkg/"
  end

  desc "Release the spira-#{File.read('VERSION').chomp}.gem file"
  task :release do
    sh "gem push pkg/spira-#{File.read('VERSION').chomp}.gem"
  end
end

YARD::Rake::YardocTask.new

desc 'Run specs'
task 'spec' do
  RSpec::Core::RakeTask.new("spec") do |t|
    t.pattern = 'spec/**/*.{spec,rb}'
    t.rspec_opts = ["-c --order rand"]
  end
end

desc 'Run specs with backtrace'
task 'tracespec' do
  RSpec::Core::RakeTask.new("tracespec") do |t|
    t.pattern = 'spec/**/*.{spec,rb}'
    t.rspec_opts = ["-bcf documentation"]
  end
end

desc 'Run coverage'
task 'coverage' do
  RSpec::Core::RakeTask.new("coverage") do |t|
    t.pattern = 'spec/**/*.{spec,rb}'
    t.rspec_opts = ["-c"]
  end
end

desc "Open an irb session with everything loaded, including test fixtures"
task :console do
  sh "irb -rubygems -I lib -r spira -I spec/fixtures -r person -r event -r cds -r cars -r posts -I spec -r spec_helper -r loading"
end

task default: [:spec]

desc "Add analytics tracking information to yardocs"
task :addanalytics do
tracking_code = <<EOC
<script type="text\/javascript">

  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-3784741-3']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text\/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https:\/\/ssl' : 'http:\/\/www') + '.google-analytics.com\/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

</script>
EOC
  files = Dir.glob('./doc/yard/**/*.html').reject { |file| %w{class_list file_list frames.html _index.html method_list}.any? { |skipfile| file.include?(skipfile) }}
  files.each do |file|
    contents = File.read(file)
    writer = File.open(file, 'w')
    writer.write(contents.gsub(/\<\/body\>/, tracking_code + "</body>"))
    writer.flush
  end
end
