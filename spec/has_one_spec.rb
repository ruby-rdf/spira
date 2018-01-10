require "spec_helper"

describe "has_one" do
  before :all do
    module ::HasOne
      class Post < Spira::Base
        type RDF::Vocab::SIOC.Post

        has_one :creator, predicate: RDF::Vocab::SIOC.has_creator, type: "HasOne::UserAccount"
        property :title, predicate: RDF::Vocab::DC.title
      end

      class UserAccount < Spira::Base
        type RDF::Vocab::SIOC.UserAccount

        has_one :account_of, predicate: RDF::Vocab::SIOC.account_of, type: "HasOne::Person"
        property :email, predicate: RDF::Vocab::SIOC.email
      end

      class Person < Spira::Base
        type RDF::Vocab::FOAF.Person

        property :name, predicate: RDF::Vocab::FOAF.name
      end
    end
  end

  before :each do
    Spira.repository = RDF::Repository.new
  end

  describe "Post" do
    subject { HasOne::Post.new }

    describe "method definitions" do
      it { is_expected.to respond_to(:creator) }
      it { is_expected.to respond_to(:creator=) }
      it { is_expected.to respond_to(:build_creator) }
      it { is_expected.to respond_to(:title) }
      it { is_expected.to respond_to(:title=) }
      it { is_expected.not_to respond_to(:build_title) }
    end

    describe "association builders" do
      it "returns instances of associated class" do
        expect(subject.build_creator).to be_a(HasOne::UserAccount)
      end
    end
  end

  describe "UserAccount" do
    subject { HasOne::UserAccount.new }

    describe "method definitions" do
      it { is_expected.to respond_to(:account_of) }
      it { is_expected.to respond_to(:account_of=) }
      it { is_expected.to respond_to(:build_account_of) }
      it { is_expected.to respond_to(:email) }
      it { is_expected.to respond_to(:email=) }
      it { is_expected.not_to respond_to(:build_email) }
    end

    describe "association builders" do
      it "returns instances of associated class" do
        expect(subject.build_account_of).to be_a(HasOne::Person)
      end
    end
  end

  describe "Person" do
    subject { HasOne::Person.new }

    describe "method definitions" do
      it { is_expected.to respond_to(:name) }
      it { is_expected.to respond_to(:name=) }
      it { is_expected.not_to respond_to(:build_name) }
    end
  end

  describe "loading from repository" do
    before :each do
      Spira.repository = RDF::Repository.load(fixture("has_one.nt"))
    end

    let(:post_uri) { RDF::URI.new("http://example.org/posts/post1") }
    let(:user_account_uri) { RDF::URI.new("http://example.org/user_accounts/user_account1") }
    let(:person_uri) { RDF::URI.new("http://example.org/people/person1") }

    subject { HasOne::Post.for(post_uri) }

    it "loads has_one associations" do
      expect(subject.creator).to be_a(HasOne::UserAccount)
      expect(subject.creator.subject).to eq(user_account_uri)
      expect(subject.creator.account_of).to be_a(HasOne::Person)
      expect(subject.creator.account_of.subject).to eq(person_uri)
    end
  end

  describe "saving to repository" do
    let(:person_uri) { RDF::URI.new("http://example.org/people/person1") }
    let(:person) { HasOne::Person.for(person_uri, name: "Jane Jones") }

    let(:user_account_uri) { RDF::URI.new("http://example.org/user_accounts/user_account1") }
    let(:user_account) { HasOne::UserAccount.for(user_account_uri, account_of: person, email: "jane@example.org") }

    let(:post_uri) { RDF::URI.new("http://example.org/posts/post1") }
    let(:post) { HasOne::Post.for(post_uri, creator: user_account, title: "Jane Says") }

    context "when object with has_one is saved" do
      it "persists the object" do
        post.save
        expect(post).to be_persisted
      end

      it "saves the association triple" do
        post.save
        expect(Spira.repository.first_object(subject: post_uri, predicate: RDF::Vocab::SIOC.has_creator)).to eq(user_account_uri)
      end

      # TODO: would it be better if it *did* persist associated objects?
      it "does not persist the associated object" do
        post.save
        expect(post.creator).not_to be_persisted
        expect(post.creator.account_of).not_to be_persisted
      end
    end
  end
end
