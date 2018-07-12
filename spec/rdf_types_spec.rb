require "spec_helper"
# These classes are to test finding based on RDF::RDFS.type


class Cars < RDF::Vocabulary('http://example.org/cars/')
  property :car
  property :van
  property :car1
  property :van
  property :station_wagon
  property :unrelated_type
end

describe 'models with a defined rdf type' do
  subject {RDF::Repository.load(fixture('types.nt'))}
  let(:car1) {Car.for Cars.car1}
  let(:car2) {Car.for Cars.car2}

  before :all do
    class ::Car < Spira::Base
      type Cars.car
      property :name, :predicate => RDF::RDFS.label
    end

    class ::Van < Spira::Base
      type Cars.van
      property :name, :predicate => RDF::RDFS.label
    end

    class ::Wagon < Spira::Base
      property :name, :predicate => RDF::RDFS.label
    end

    class ::MultiCar < Spira::Base
      type Cars.car
      type Cars.van
    end
  end

  before {Spira.repository = subject}

  context "when declaring types" do
    it "should raise an error when declaring a non-uri type" do
      expect {
        class ::XYZ < Spira::Base
          type 'a string, for example'
        end
      }.to raise_error TypeError
    end

    it "should provide a class method which returns the type" do
      expect(Car).to respond_to :type
    end

    it "should return the correct type" do
      expect(Car.type).to eql Cars.car
    end

    it "should return nil if no type is declared" do
      expect(Wagon.type).to eql nil
    end
  end

  context "When finding by types" do
    it "should find 1 car" do
      expect(Car.count).to eql 1
    end

    it "should find 3 vans" do
      expect(Van.count).to eql 3
    end
  end

  context "when creating" do
    subject {Car.for RDF::URI.new('http://example.org/cars/newcar')}

    its(:type) {is_expected.to eql Car.type}

    it "should not include a type statement on dump" do
      # NB: declaring an object with a type does not get the type statement in the DB
      # until the object is persisted!
      expect(subject).not_to have_statement(:predicate => RDF.type, :object => Car.type)
    end

    it "should not be able to assign type" do
      expect {
        Car.for(RDF::URI.new('http://example.org/cars/newcar2'), :type => Cars.van)
      }.to raise_error NoMethodError
    end

  end

  context "when loading" do
    it "should have a type" do
      expect(car1.type).to eql Car.type
    end

    it "should have a type when loading a resource without one in the data store" do
      expect(car2.type).to eql Car.type
    end
  end

  context "when saving" do
    it "should save a type for resources which don't have one in the data store" do
      car2.save!
      expect(subject.query(:subject => Cars.car2, :predicate => RDF.type, :object => Cars.car).count).to eql 1
    end

    it "should save a type for newly-created resources which in the data store" do
      car3 = Car.for(Cars.car3)
      car3.save!
      expect(subject.query(:subject => Cars.car3, :predicate => RDF.type, :object => Cars.car).count).to eql 1
    end
  end

  context "When getting/setting" do
    before :each do
      expect(car1).not_to be_nil
    end

    it "should allow setting other properties" do
      car1.name = "prius"
      car1.save!
      expect(car1.type).to eql Cars.car
      expect(car1.name).to eql "prius"
    end

    it "should raise an exception when trying to change the type" do
      expect {car1.type = Cars.van}.to raise_error(NoMethodError)
    end

    it "should maintain all triples related to this object on save" do
      original_triples = subject.query(:subject => Cars.car1)
      car1.name = 'testing123'
      car1.save!
      expect(subject.query(:subject => Cars.car1).count).to eql original_triples.size
    end
  end

  context "when counting" do
    it "should count all projected types" do
      expect {
        Car.for(Cars.one).save!
        Van.for(Cars.two).save!
      }.to change(MultiCar, :count).by(2)
    end

    it "should provide a count method for resources with types" do
      expect(Car.count).to eql 1
    end

    it "should increase the count when items are saved" do
      Car.for(Cars.toyota).save!
      expect(Car.count).to eql 2
    end

    it "should decrease the count when items are destroyed" do
      expect { car1.destroy }.to change(Car, :count).from(1).to(0)
    end

    it "should raise a Spira::NoTypeError to call #count for models without types" do
      expect { Wagon.count }.to raise_error Spira::NoTypeError
    end
  end

  context "when enumerating" do
    it "should provide an each method for resources with types" do
      expect(Van.each.to_a.size).to eql 3
    end

    it "should raise a Spira::NoTypeError to call #each for models without types" do
      expect { Wagon.each }.to raise_error Spira::NoTypeError
    end

    it "should return an enumerator if no block is given" do
      expect(Van.each).to be_a Enumerator
    end

    it "should execute a block if one is given" do
      vans = []
      Van.each do |resource|
        vans << resource
      end
      [Cars.van1, Cars.van2, Cars.van3].each do |uri|
        expect(vans.any? { |van| van.uri == uri }).to be_truthy
      end
    end
  end

end
