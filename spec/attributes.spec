require "spec_helper"

describe "RDF::Resource attributes" do
  before do
    Spira.add_repository :default, RDF::Repository.new

    class Person
      include Spira::Resource
      property :name, :predicate => RDFS.label
      has_many :friends, :predicate => FOAF.knows, :type => :Person
    end

    friend = Person.new(:name => "Dick")
    friend.save!

    @person = Person.new(:name => "Charlie")
    @person.friends << friend
    @person.save!
  end

  describe "#reload" do
    it "should reload single-value attributes from the repository" do
      @person.name = "Jennifer"

      lambda {
        @person.reload
      }.should change(@person, :name).from("Jennifer").to("Charlie")
    end

    it "should reload list attributes from the repository" do
      friend = Person.new(:name => "Bob")
      friend.save!
      @person.friends << friend

      @person.should have(2).friends

      @person.reload
      @person.should have(1).friends
    end
  end
end
