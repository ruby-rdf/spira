require "bundler/setup"
require 'rdf/spec/enumerable'
require 'rdf/spec'
require 'rdf/isomorphic'
require 'rdf/ntriples'
require 'rdf/turtle'
require 'rdf/vocab'
require 'amazing_print'

begin
  require 'simplecov'
  require 'simplecov-lcov'

  SimpleCov::Formatter::LcovFormatter.config do |config|
    #Coveralls is coverage by default/lcov. Send info results
    config.report_with_single_file = true
    config.single_report_path = 'coverage/lcov.info'
  end

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::LcovFormatter
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
