require "spec_helper"

describe 'types for properties' do

  context "when declaring type classes" do
    context "in a separate thread" do
      it "should be available" do
        types = {}
        t = Thread.new { types = Spira.types }
        t.join

        types.should satisfy do |ts|
          ts.any? && ts == Spira.types
        end
      end

      it "should be declared" do
        lambda {
          t = Thread.new do
            class ::PropTypeA < Spira::Base
              configure :default_vocabulary => RDF::URI.new('http://example.org/vocab'),
                        :base_uri => RDF::URI.new('http://example.org/props')

              property :test, :type => XSD.string
            end
          end
          t.join
        }.should_not raise_error TypeError
      end
    end

    it "should raise a type error to use a type that has not been declared" do
      lambda {
        class ::PropTypeA < Spira::Base
          configure :default_vocabulary => RDF::URI.new('http://example.org/vocab'),
                    :base_uri => RDF::URI.new('http://example.org/props')

          property :test, :type => XSD.non_existent_type
        end
      }.should raise_error TypeError
    end

    it "should not raise a type error to use a symbol type, even if the class has not been declared yet" do
      lambda {
        class ::PropTypeB < Spira::Base
          configure :default_vocabulary => RDF::URI.new('http://example.org/vocab'),
                    :base_uri => RDF::URI.new('http://example.org/props')

          property :test, :type => :non_existent_type
        end
      }.should_not raise_error TypeError
    end

    it "should not raise an error to use an included XSD type aliased to a Spira type" do
      lambda {
        class ::PropTypeD < Spira::Base
          configure :default_vocabulary => RDF::URI.new('http://example.org/vocab'),
                    :base_uri => RDF::URI.new('http://example.org/props')

          property :test, :type => XSD.string
        end
      }.should_not raise_error TypeError
    end

    it "should not raise an error to use an included Spira type" do
      lambda {
        class ::PropTypeC < Spira::Base
          configure :default_vocabulary => RDF::URI.new('http://example.org/vocab'),
                    :base_uri => RDF::URI.new('http://example.org/props')

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
          RDF::Literal.new(value, :datatype => XSD.test_type)
        end

        def self.unserialize(value)
          value.value
        end

        register_alias XSD.test_type
      end

      class ::PropTest < Spira::Base
        configure :default_vocabulary => RDF::URI.new('http://example.org/vocab'),
                  :base_uri => RDF::URI.new('http://example.org/props')

        property :test,      :type => TestType
        property :xsd_test,  :type => XSD.test_type
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
