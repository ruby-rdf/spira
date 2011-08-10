require File.dirname(File.expand_path(__FILE__)) + '/../spec_helper'

describe Spira::Types::Date do
  
  before :all do
    @date = Date.today
  end

  context "when serializing" do
    it "should serialize dates to XSD dates" do
      serialized = Spira::Types::Date.serialize(@date)
      serialized.should be_a RDF::Literal
      serialized.should have_datatype
      serialized.datatype.should == RDF::XSD.date
      serialized.should == RDF::Literal.new(@date, :datatype => RDF::XSD.date)
    end
  end

  context "when unserializing" do
    it "should unserialize XSD dates to dates" do
      value = Spira::Types::Date.unserialize(RDF::Literal.new(@date, :datatype => RDF::XSD.date))
      value.should equal @date
    end
  end


end

