require "spec_helper"

describe Spira::Types::Any do

  before :all do
    @uri = RDF::URI('http://example.org')
  end

  # this spec is going to be necessarily loose.  The 'Any' type is defined to
  # use RDF.rb's automatic RDF Literal boxing and unboxing, which may or may
  # not change between verions.
  #
  context "when serializing" do
    it "should serialize literals to RDF Literals" do
      serialized = Spira::Types::Any.serialize(15)
      expect(serialized).to be_a RDF::Literal
      serialized = Spira::Types::Any.serialize("test")
      expect(serialized).to be_a RDF::Literal
    end

    it "should keep RDF::URIs as URIs" do
      expect(Spira::Types::Any.serialize(@uri)).to eql @uri
    end

    it "should fail to serialize collections" do
      expect { Spira::Types::Any.serialize([]) }.to raise_error TypeError
    end
  end

  context "when unserializing" do
    specify "datatyped literal" do
      expect(Spira::Types::Any.unserialize(RDF::Literal(5))).to eq 5
    end
    specify "plain literal" do
      expect(Spira::Types::Any.unserialize(RDF::Literal("a string"))).to eq "a string"
    end

    specify "URI" do
      expect(Spira::Types::Any.unserialize(@uri)).to include(
        :scheme=>"http",
        :authority=>"example.org",
        :host=>"example.org"
      )
    end
  end


end

