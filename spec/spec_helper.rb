require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start do
  add_filter '/.bundle/'
end

require 'spira'
require 'rdf/spec/enumerable'
require 'rdf/spec'
require 'rdf/isomorphic'

require 'i18n'
I18n.enforce_available_locales = false

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.exclusion_filter = {
    :ruby           => lambda { |version| RUBY_VERSION.to_s !~ /^#{version}/},
  }
end

def fixture(filename)
  File.join(File.dirname(__FILE__),'fixtures', filename)
end
