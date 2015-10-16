source "https://rubygems.org"
gemspec

gem 'rake', '~> 10.0'
gem 'rdf', git: "git://github.com/ruby-rdf/rdf.git", branch: "develop"

group :development, :test do
  gem 'rdf-spec', git: "git://github.com/ruby-rdf/rdf-spec.git", branch: "develop"
  gem 'byebug',    platform: :mri_21
  gem 'redcarpet', '~> 3.2.2' unless RUBY_ENGINE == 'jruby'
  gem 'psych',      platforms: [:mri, :rbx]
end

group :test do
  gem 'coveralls', :require => false
  gem 'simplecov', '~> 0.10', :require => false
  gem 'guard' #, '~> 2.13.0'
  gem 'guard-rspec' #, '~> 3.1.0'
  gem 'guard-ctags-bundler' #, '~> 1.4.0'
end

#group :debug do
#  gem "debugger", :platforms => [:mri_19, :mri_20]
#  gem "ruby-debug", :platforms => [:jruby]
#end
