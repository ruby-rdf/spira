require 'spira'
require 'rdf/spec/enumerable'
require 'rdf/spec'
require 'rdf/isomorphic'

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
