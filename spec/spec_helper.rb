$:.unshift(File.join(File.dirname(__FILE__),'..','lib'))
$:.unshift(File.join(File.dirname(__FILE__),'fixtures',''))
#$:.unshift(File.join(File.dirname(__FILE__),'..','..','rdf-spec','lib'))
#$:.unshift(File.join(File.dirname(__FILE__),'..','..','rdf','lib'))
#$:.unshift(File.join(File.dirname(__FILE__),'..','..','rdf-isomorphic','lib'))
require 'spira'
require 'rdf/spec/enumerable'
require 'rdf/spec'
require 'rdf/isomorphic'

def fixture(filename)
  File.join(File.dirname(__FILE__),'fixtures',filename)
end

