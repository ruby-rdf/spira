require File.dirname(__FILE__) + "/spec_helper.rb"

describe 'finding based on types' do


  before :all do
    require 'cars'
    require 'rdf/ntriples'
    @types_repository = RDF::Repository.load(fixture('types.nt'))
    Spira.add_repository(:default, @types_repository)
  end

  context "When finding by types" do
    it "should find 1 car" do
      Car.count.should == 1
    end

    it "should find 3 vans" do
      Van.count.should == 3
    end

  end

  context "When getting/setting" do
    before :each do
      @car = Car.find Cars.car1
      @car.nil?.should_not be_true
      @types_repository = RDF::Repository.load(fixture('types.nt'))
      Car.repository = @types_repository
    end

    it "should allow setting other properties" do
      @car.name = "prius"
      @car.save!
      @car.type.should == Cars.car
      @car.name.should == "prius"
    end

    it "should raise an exception when trying to change the type" do
      lambda {@car.type = Cars.van}.should raise_error TypeError
    end

    it "should maintain types on save not related to this model" do
      pending "Need to implement has_many first"
      @car.types.should == [Cars.car]
    end

    it "should maintain all triples related to this object on save" do
      @car.name = 'testing123'
      @car.save!
      @types_repository.query(:subject => Cars.car1).should == @car
    end
  end

  context "examining types" do
    it "should have a list of RDF.types" do
      pending "Investigate if this will use the same has_many setup"
    end
  end

end
