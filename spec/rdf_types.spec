require File.dirname(__FILE__) + "/spec_helper.rb"
# These classes are to test finding based on rdfs.type


class Cars < RDF::Vocabulary('http://example.org/cars/')
  property :car
  property :van
  property :car1
  property :van
  property :station_wagon
  property :unrelated_type
end


class Car
  include Spira::Resource

  type Cars.car

  property :name, :predicate => RDFS.label
end

class Van
  include Spira::Resource

  type Cars.van

  property :name, :predicate => RDFS.label
end

class Wagon
  include Spira::Resource

  property :name, :predicate => RDFS.label
end

describe 'finding based on types' do


  before :all do
    require 'rdf/ntriples'
    @types_repository = RDF::Repository.load(fixture('types.nt'))
    Spira.add_repository(:default, @types_repository)
  end

  context "when declaring types" do
    it "should raise an error when declaring a non-uri type" do
      lambda {
        class XYZ
          include Spira::Resource
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
      @car = Car.create RDF::URI.new('http://example.org/cars/newcar')
    end

    it "should have a type on creation" do
      @car.type.should == Car.type
    end

    it "should include a type statement on dump" do
      @car.query(:predicate => RDF.type).count.should == 1
      @car.query(:predicate => RDF.type).first.object.should == Car.type
      @car.query(:predicate => RDF.type).first.subject.should == @car.uri
    end

    it "should raise a type error to send a type attribute to a class with a type on instantiation" do
      lambda { Car.create RDF::URI.new('http://example.org/cars/newcar2'), :type => Cars.van }.should raise_error TypeError
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

    it "should maintain all triples related to this object on save" do
      original_triples = @types_repository.query(:subject => Cars.car1)
      @car.name = 'testing123'
      @car.save!
      @types_repository.query(:subject => Cars.car1).count.should == original_triples.size
    end
  end

end
