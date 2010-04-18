require 'rubygems'
require 'spec'
require 'spec/rake/spectask'

desc 'Run specs'
task 'spec' do
  Spec::Rake::SpecTask.new("spec") do |t|
    t.spec_files = FileList["spec/**/*.spec","spec/*.rb"]
    t.rcov = true
    t.spec_opts = ["-c"]
  end
end

desc 'Run specs with backtrace'
task 'tracespec' do
  Spec::Rake::SpecTask.new("tracespec") do |t|
    t.spec_files = FileList["spec/**/*.spec"]
    t.rcov = false
    t.spec_opts = ["-bcfn"]
  end
end

desc "Open an irb session with everything loaded, including test fixtures"
task :console do
  sh "irb -rubygems -I lib -r spira -I spec/fixtures -r person -r event -r cds -r cars -r posts -I spec -r spec_helper"
end

task :default => [:spec]

desc "Upload docs to rubyforge"
task :uploadyardocs do
  `rsync -av doc/yard/* bhuga@rubyforge.org:/var/www/gforge-projects/spira`
end
