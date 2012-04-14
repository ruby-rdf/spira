require "spec_helper"
# These classes are to test finding based on rdfs.type


class Cars < RDF::Vocabulary('http://example.org/cars/')
  property :car
  property :van
  property :car1
  property :van
  property :station_wagon
  property :unrelated_type
end

describe 'models with a defined rdf type' do


  before :all do
    require 'rdf/ntriples'

    class ::Car < Spira::Base
      type Cars.car
      property :name, :predicate => RDFS.label
    end
    
    class ::Van < Spira::Base
      type Cars.van
      property :name, :predicate => RDFS.label
    end
    
    class ::Wagon < Spira::Base
      property :name, :predicate => RDFS.label
    end
  end

  before :each do
    @types_repository = RDF::Repository.load(fixture('types.nt'))
    Spira.add_repository(:default, @types_repository)
  end

  context "when declaring types" do
    it "should raise an error when declaring a non-uri type" do
      lambda {
        class ::XYZ < Spira::Base
          type 'a string, for example'
        end
      }.should raise_error TypeError
    end

    it "should provide a class method which returns the type" do
      Car.should respond_to :type
    end
    
    it "should return the correct type" do
      Car.type.should == Cars.car
    end

    it "should return nil if no type is declared" do
      Wagon.type.should == nil
    end
  end

  context "When finding by types" do
    it "should find 1 car" do
      Car.count.should == 1
    end

    it "should find 3 vans" do
      Van.count.should == 3
    end

  end

  context "when creating" do
   
    before :each do
      @car = Car.for RDF::URI.new('http://example.org/cars/newcar')
    end

    it "should have a type on creation" do
      @car.type.should == Car.type
    end

    it "should include a type statement on dump" do
      @car.query(:predicate => RDF.type).count.should == 1
      @car.query(:predicate => RDF.type).first.object.should == Car.type
      @car.query(:predicate => RDF.type).first.subject.should == @car.uri
    end

    it "should raise a type error when receiving a type attribute option on instantiation" do
      lambda { Car.for RDF::URI.new('http://example.org/cars/newcar2'), :type => Cars.van }.should raise_error TypeError
    end

  end

  context "when loading" do
    before :each do
      @car1 = Car.for Cars.car1
      @car2 = Car.for Cars.car2
    end

    it "should have a type" do
      @car1.type.should == Car.type
    end

    it "should have a type when loading a resource without one in the data store" do
      @car2.type.should == Car.type
    end
  end

  context "when saving" do
    before :each do
      @car2 = Car.for Cars.car2
    end

    it "should save a type for resources which don't have one in the data store" do
      @car2.save!
      @types_repository.query(:subject => Cars.car2, :predicate => RDF.type, :object => Cars.car).count.should == 1
    end

    it "should save a type for newly-created resources which in the data store" do
      car3 = Car.for(Cars.car3)
      car3.save!
      @types_repository.query(:subject => Cars.car3, :predicate => RDF.type, :object => Cars.car).count.should == 1
    end
  end

  context "When getting/setting" do
    before :each do
      @car = Car.for Cars.car1
      @car.nil?.should_not be_true
    end

    it "should allow setting other properties" do
      @car.name = "prius"
      @car.save!
      @car.type.should == Cars.car
      @car.name.should == "prius"
    end

    it "should raise an exception when trying to change the type" do
      lambda {@car.type = Cars.van}.should raise_error
    end

    it "should maintain all triples related to this object on save" do
      original_triples = @types_repository.query(:subject => Cars.car1)
      @car.name = 'testing123'
      @car.save!
      @types_repository.query(:subject => Cars.car1).count.should == original_triples.size
    end
  end

  context "when counting" do
    it "should provide a count method for resources with types" do
      Car.count.should == 1
    end

    it "should increase the count when items are saved" do
      Car.for(Cars.toyota).save!
      Car.count.should == 2
    end

    it "should decrease the count when items are destroyed" do
      Car.for(Cars.car1).destroy!
      Car.count.should == 0
    end

    it "should raise a Spira::NoTypeError to call #count for models without types" do
      lambda { Wagon.count }.should raise_error Spira::NoTypeError
    end
  end

  context "when enumerating" do
    it "should provide an each method for resources with types" do
      Van.each.to_a.size.should == 3
    end

    it "should raise a Spira::NoTypeError to call #each for models without types" do
      lambda { Wagon.each }.should raise_error Spira::NoTypeError
    end

    it "should return an enumerator if no block is given" do
      Van.each.should be_a RDF::Enumerator
    end

    it "should execute a block if one is given" do
      vans = []
      Van.each do |resource|
        vans << resource
      end
      [Cars.van1, Cars.van2, Cars.van3].each do |uri|
        vans.any? { |van| van.uri == uri }.should be_true
      end
    end
  end

end
