source "https://rubygems.org"
gemspec

gem 'rake', '~> 10.0'

group :test do
  gem 'coveralls', :require => false
  gem 'rspec', '~> 2.14.1'
  gem 'rdf-spec', '= 1.1.3' # later version depend on rspec-its which implies rspec >= 3.0
  gem 'yard', '~> 0.8'
  gem 'simplecov', '~> 0.10', :require => false
  gem 'redcarpet', '~> 3.2.2' unless RUBY_ENGINE == 'jruby'
  gem 'guard', '~> 2.13.0'
  gem 'guard-rspec', '~> 3.1.0'
  gem 'guard-ctags-bundler', '~> 1.4.0'
end

#group :debug do
#  gem "debugger", :platforms => [:mri_19, :mri_20]
#  gem "ruby-debug", :platforms => [:jruby]
#end
