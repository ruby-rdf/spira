require File.dirname(File.expand_path(__FILE__)) + '/spec_helper'

describe 'types for properties' do

  before :all do
  end


  context "when declaring type classes" do
    it "should raise a type error to use a type that has not been declared" do
      lambda {
        class ::PropTypeA
          include Spira::Resource
          default_vocabulary RDF::URI.new('http://example.org/vocab')
          base_uri RDF::URI.new('http://example.org/props')

          property :test, :type => RDF::XSD.non_existent_type
        end
      }.should raise_error TypeError
    end

    it "should not raise a type error to use a symbol type, even if the class has not been declared yet" do
      lambda {
        class ::PropTypeB
          include Spira::Resource
          default_vocabulary RDF::URI.new('http://example.org/vocab')
          base_uri RDF::URI.new('http://example.org/props')

          property :test, :type => :non_existent_type
        end
      }.should_not raise_error TypeError
    end

    it "should not raise an error to use an included XSD type aliased to a Spira type" do
      lambda {
        class ::PropTypeD
          include Spira::Resource
          default_vocabulary RDF::URI.new('http://example.org/vocab')
          base_uri RDF::URI.new('http://example.org/props')

          property :test, :type => RDF::XSD.string
        end
      }.should_not raise_error TypeError
    end

    it "should not raise an error to use an included Spira type" do
      lambda {
        class ::PropTypeC
          include Spira::Resource
          default_vocabulary RDF::URI.new('http://example.org/vocab')
          base_uri RDF::URI.new('http://example.org/props')

          property :test, :type => String
        end
      }.should_not raise_error TypeError
    end

  end

  # These tests are to make sure that type declarations and mappings work
  # correctly.  For specific type boxing/unboxing, see the types/ folder.
  context 'when declaring types for properties' do

    before :all do

      @property_types_repo = RDF::Repository.new
      Spira.add_repository(:default, @property_types_repo)

      class ::TestType
        include Spira::Type
      
        def self.serialize(value)
          RDF::Literal.new(value, :datatype => RDF::XSD.test_type)
        end

        def self.unserialize(value)
          value.value
        end

        register_alias RDF::XSD.test_type
      end

      class ::PropTest
      
        include Spira::Resource
        
        default_vocabulary RDF::URI.new('http://example.org/vocab')
        base_uri RDF::URI.new('http://example.org/props')
      
        property :test,      :type => TestType
        property :xsd_test,  :type => RDF::XSD.test_type
      end
    end

    before :each do
      @resource = PropTest.for 'test'
    end

    it "uses the given serialize function" do
      @resource.test = "a string"
      @resource.should have_object RDF::Literal.new("a string", :datatype => RDF::XSD.test_type)
    end
    
    it "uses the given unserialize function" do
      @resource.test = "a string"
      @resource.save!
      @resource.test.should == "a string"
      @resource.test.should == PropTest.for('test').test
    end

    it "correctly associates a URI datatype alias to the correct class" do
      Spira.types[RDF::XSD.test_type].should == TestType
      PropTest.properties[:xsd_test][:type].should == TestType
    end

  end


end
