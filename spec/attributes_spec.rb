require "spec_helper"

describe "RDF::Resource attributes" do
  let(:person) do
    Spira.repository = RDF::Repository.new

    class Person < Spira::Base
      property :name, :predicate => RDF::RDFS.label
      has_many :friends, :predicate => RDF::Vocab::FOAF.knows, :type => :Person
    end

    friend = Person.new(:name => "Dick")
    friend.save!

    p = Person.new(:name => "Charlie")
    p.friends << friend
    p.save!
  end

  describe "#reload" do
    it "should reload single-value attributes from the repository" do
      person.name = "Jennifer"

      expect {
        person.reload
      }.to change(person, :name).from("Jennifer").to("Charlie")
    end

    it "should reload list attributes from the repository" do
      friend = Person.new(:name => "Bob")
      friend.save!
      person.friends << friend

      expect(person.friends.length).to eql 2

      person.reload
      expect(person.friends.length).to eql 1
    end
  end

  context "when assigning a value to a non-existing property" do
    context "via #update_attributes" do
      it "should raise a NoMethodError" do
        expect {
          person.update_attributes(:nonexisting_attribute => 0)
        }.to raise_error NoMethodError
      end
    end

    context "via #write_attribute" do
      it "should raise a Spira::PropertyMissingError" do
        expect {
          person.send :write_attribute, :nonexisting_attribute, 0
        }.to raise_error Spira::PropertyMissingError
      end
    end
  end

end
