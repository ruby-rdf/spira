require File.dirname(File.expand_path(__FILE__)) + '/../spec_helper'

describe Spira::Types::DateTime do
  
  before :all do
    @date = DateTime.now
  end

  context "when serializing" do
    it "should serialize datetimes to XSD datetimes" do
      serialized = Spira::Types::DateTime.serialize(@date)
      serialized.should be_a RDF::Literal
      serialized.should have_datatype
      serialized.datatype.should == RDF::XSD.dateTime
      serialized.should == RDF::Literal.new(@date, :datatype => RDF::XSD.dateTime)
    end
  end

  context "when unserializing" do
    it "should unserialize XSD datetimes to datetimes" do
      value = Spira::Types::DateTime.unserialize(RDF::Literal.new(@date, :datatype => RDF::XSD.dateTime))
      value.should equal @date
    end
  end


end

