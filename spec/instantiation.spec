require File.dirname(__FILE__) + "/spec_helper.rb"

describe Spira do

  context "when instantiating" do

    before :all do
      class ::InstantiationTest
        include Spira::Resource

        property :name, :predicate => FOAF.name

      end
      Spira.add_repository(:default, RDF::Repository.new)
    end


    context "when instantiating from a URI" do
      before :each do
        @uri = RDF::URI('http://example.org/example')
      end

      it "should allow instantiation from a URI" do
        @uri.as(InstantiationTest).should be_a InstantiationTest
      end

      it "should allow instantiation from a URI with attributes given" do
        test = @uri.as(InstantiationTest, :name => "a name")
        test.name.should == "a name"
      end
    end


  end
end
