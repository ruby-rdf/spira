require 'rdf/spec/enumerable'
require 'rdf/spec'
require 'rdf/isomorphic'
require 'rdf/ntriples'
require 'rdf/turtle'
require 'rdf/vocab'

begin
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ])
  SimpleCov.start do
    add_filter '/.bundle/'
  end
rescue LoadError
end

require 'spira'

require 'i18n'
I18n.enforce_available_locales = false

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.exclusion_filter = {
    :ruby           => lambda { |version| RUBY_VERSION.to_s !~ /^#{version}/},
  }
end

def fixture(filename)
  File.join(File.dirname(__FILE__),'fixtures', filename)
end
