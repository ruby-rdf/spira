require "spec_helper"

describe 'types for properties' do

  context "when declaring type classes" do
    context "in a separate thread" do
      it "should be available" do
        types = {}
        t = Thread.new { types = Spira.types }
        t.join

        expect(types).to satisfy do |ts|
          ts.any? && ts == Spira.types
        end
      end

      it "should be declared" do
        expect {
          t = Thread.new do
            class ::PropTypeA < Spira::Base
              configure default_vocabulary: RDF::URI.new('http://example.org/vocab'),
                        base_uri: RDF::URI.new('http://example.org/props')

              property :test, type: XSD.string
            end
          end
          t.join
        }.not_to raise_error
      end
    end

    it "should raise a type error to use a type that has not been declared" do
      expect {
        class ::PropTypeA < Spira::Base
          configure default_vocabulary: RDF::URI.new('http://example.org/vocab'),
                    base_uri: RDF::URI.new('http://example.org/props')

          property :test, type: XSD.non_existent_type
        end
      }.to raise_error TypeError
    end

    it "should not raise a type error to use a symbol type, even if the class has not been declared yet" do
      expect {
        class ::PropTypeB < Spira::Base
          configure default_vocabulary: RDF::URI.new('http://example.org/vocab'),
                    base_uri: RDF::URI.new('http://example.org/props')

          property :test, type: :non_existent_type
        end
      }.not_to raise_error
    end

    it "should not raise an error to use an included XSD type aliased to a Spira type" do
      expect {
        class ::PropTypeD < Spira::Base
          configure default_vocabulary: RDF::URI.new('http://example.org/vocab'),
                    base_uri: RDF::URI.new('http://example.org/props')

          property :test, type: XSD.string
        end
      }.not_to raise_error
    end

    it "should not raise an error to use an included Spira type" do
      expect {
        class ::PropTypeC < Spira::Base
          configure default_vocabulary: RDF::URI.new('http://example.org/vocab'),
                    base_uri: RDF::URI.new('http://example.org/props')

          property :test, type: String
        end
      }.not_to raise_error
    end

  end

  # These tests are to make sure that type declarations and mappings work
  # correctly.  For specific type boxing/unboxing, see the types/ folder.
  context 'when declaring types for properties' do

    before :all do

      Spira.repository = RDF::Repository.new

      class ::TestType
        include Spira::Type

        def self.serialize(value)
          RDF::Literal.new(value, datatype: XSD.test_type)
        end

        def self.unserialize(value)
          value.value
        end

        register_alias XSD.test_type
      end

      class ::PropTest < Spira::Base
        configure default_vocabulary: RDF::URI.new('http://example.org/vocab'),
                  base_uri: RDF::URI.new('http://example.org/props')

        property :test,      type: TestType
        property :xsd_test,  type: XSD.test_type
      end
    end

    subject {PropTest.for 'test'}

    it "uses the given serialize function" do
      subject.test = "a string"
      expect(subject).to have_object RDF::Literal.new("a string", datatype: RDF::XSD.test_type)
    end

    it "uses the given unserialize function" do
      subject.test = "a string"
      subject.save!
      expect(subject.test).to eql "a string"
      expect(subject.test).to eql PropTest.for('test').test
    end

    it "correctly associates a URI datatype alias to the correct class" do
      expect(Spira.types[RDF::XSD.test_type]).to eql TestType
      expect(PropTest.properties[:xsd_test][:type]).to eql TestType
    end

  end

end
