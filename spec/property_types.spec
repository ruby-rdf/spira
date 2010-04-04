require File.dirname(__FILE__) + "/spec_helper.rb"

class RubyProps

  include Spira::Resource
  
  default_vocabulary RDF::URI.new('http://example.org/vocab')
  base_uri RDF::URI.new('http://example.org/props')

  property :integer, :type => Integer
  property :string,  :type => String
  property :float,   :type => Float


end

class XSDProps

  include Spira::Resource
  
  default_vocabulary RDF::URI.new('http://example.org/vocab')
  base_uri RDF::URI.new('http://example.org/props')

  property :boolean, :type => XSD.boolean
  property :integer, :type => XSD.integer
  property :string,  :type => XSD.string
  property :float,   :type => XSD.float


end


describe 'types for properties' do

  before :all do
  end

  context 'when ruby types are specified' do
    context "appropriate XSD datatype for a set property" do
      
      before :each do
        @resource = RubyProps.create 'test'
      end

      context "it uses XSD.integer for Integer" do
        it "saves a fixnum as an XSD.integer" do
          @resource.integer = 15
          @resource.should have_object RDF::Literal.new(15)
        end
    
        it "typecasts strings to integers" do
          pending "Tough call.  typecasting is an implicit validation, and of course ruby's to_i on a string => 0 doesn't help."
          @resource.integer = "15"
          @resource.should have_object RDF::Literal.new(15)
        end

      end
    end
  end

  context 'when XSD types are specified' do

  end



end
