source "https://rubygems.org"
gemspec

gem 'rake', '~> 10.0'

group :test do
  gem 'coveralls', :require => false
  gem 'rspec', '~> 2.14'
  gem 'rdf-spec', '~> 1.1'
  gem 'yard', '~> 0.8'
  gem 'simplecov', '~> 0.7', :require => false
  gem 'redcarpet', '~> 2.2.2' unless RUBY_ENGINE == 'jruby'
  gem 'guard', '~> 1.2.3'
  gem 'guard-rspec', '~> 1.1.0'
  gem 'guard-ctags-bundler', '~> 0.1.1'
end

group :debug do
  gem "debugger", :platforms => [:mri_19, :mri_20]
  gem "ruby-debug", :platforms => [:jruby]
end
