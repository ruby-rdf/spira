source "https://rubygems.org"
gemspec

gem 'rdf', github: "ruby-rdf/rdf", branch: "develop"

group :development, :test do
  gem 'ebnf',           github: "gkellogg/ebnf",            branch: "develop"
  gem 'rdf-isomorphic', github: "ruby-rdf/rdf-isomorphic",  branch: "develop"
  gem 'rdf-spec',       github: "ruby-rdf/rdf-spec",        branch: "develop"
  gem 'rdf-turtle',     github: "ruby-rdf/rdf-turtle",      branch: "develop"
  gem 'rdf-vocab',      github: "ruby-rdf/rdf-vocab",       branch: "develop"
  gem 'sxp',            github: "gkellogg/sxp-ruby",        branch: "master"
  gem 'rake',           '~> 10.0'
  gem 'redcarpet',      '~> 3.2.2' unless RUBY_ENGINE == 'jruby'
  gem 'byebug',         platform: :mri
  gem 'psych',          platforms: [:mri, :rbx]
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
