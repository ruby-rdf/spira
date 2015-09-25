require "spec_helper"

describe 'Spira resources' do

  before :all do
    class ::HookTest < ::Spira::Base
      property :name, :predicate => FOAF.name
      property :age,  :predicate => FOAF.age
    end
  end
  subject {RDF::URI.intern('http://example.org/test')}
  let(:repository) do
    RDF::Repository.new do |repo|
      repo << RDF::Statement.new(subject, RDF::FOAF.name, "A name")
    end
  end

  before {Spira.repository = repository}

  context "with a before_create method" do
    before :all do
      class ::BeforeCreateTest < ::HookTest
      type FOAF.Person
        before_create :update_name

        def update_name
          self.name = "Everyone has this name"
        end
      end

      class ::BeforeCreateWithoutTypeTest < ::HookTest
        def before_create
          self.name = "Everyone has this name"
        end
      end
    end

    before {repository << RDF::Statement.new(subject, RDF.type, RDF::FOAF.Person)}

    it "calls the before_create method before saving a resouce for the first time" do
      test = RDF::URI('http://example.org/new').as(::BeforeCreateTest)
      test.save
      expect(test.name).to eql "Everyone has this name"
      expect(repository).to have_statement RDF::Statement.new(test.subject, RDF::FOAF.name, "Everyone has this name")
    end

    it "does not call the before_create method if the resource previously existed" do
      test = subject.as(::BeforeCreateTest)
      test.save
      expect(test.name).to eql "A name"
      expect(repository).to have_statement RDF::Statement.new(test.subject, RDF::FOAF.name, "A name")
      expect(repository).not_to have_statement RDF::Statement.new(test.subject, RDF::FOAF.name, "Everyone has this name")
    end

    it "does not call the before_create method without a type declaration" do
      test = RDF::URI('http://example.org/new').as(::BeforeCreateWithoutTypeTest)
      test.save
      expect(repository).not_to have_statement RDF::Statement.new(test.subject, RDF::FOAF.name, "Everyone has this name")
    end
  end

  context "with an after_create method" do
    before :all do
      class ::AfterCreateTest < ::HookTest
        type FOAF.Person
        after_create :update_name

        def update_name
          self.name = "Everyone has this unsaved name"
        end
      end

      class ::AfterCreateWithoutTypeTest < ::HookTest
        after_create :update_name

        def update_name
          self.name = "Everyone has this unsaved name"
        end
      end
    end

    before {repository << RDF::Statement.new(subject, RDF.type, RDF::FOAF.Person)}

    it "calls the after_create method after saving a resource for the first time" do
      test = RDF::URI('http://example.org/new').as(::AfterCreateTest)
      test.save
      expect(test.name).to eql "Everyone has this unsaved name"
      expect(repository).not_to have_statement RDF::Statement.new(test.subject, RDF::FOAF.name, "Everyone has this name")
    end

    it "does not call after_create if the resource previously existed" do
      test = subject.as(::AfterCreateTest)
      test.save
      expect(test.name).to eql "A name"
      expect(repository).to have_statement RDF::Statement.new(test.subject, RDF::FOAF.name, "A name")
      expect(repository).not_to have_statement RDF::Statement.new(test.subject, RDF::FOAF.name, "Everyone has this name")
    end

    it "does not call the after_create method without a type declaration" do
      test = RDF::URI('http://example.org/new').as(::AfterCreateWithoutTypeTest)
      test.save
      expect(test.name).to be_nil
    end
  end

  context "with an after_update method" do

    before :all do
      class ::AfterUpdateTest < ::HookTest
        after_update :update_age

        def update_age
          self.age = 15
        end
      end
    end

    it "calls the after_update method after updating a field" do
      test = subject.as(AfterUpdateTest)
      expect(test.age).to be_nil
      test.update_attributes(:name => "A new name")
      expect(test.age).to eql 15
    end

    it "does not call the after_update method after simply setting a field" do
      test = subject.as(AfterUpdateTest)
      expect(test.age).to be_nil
      test.name = "a new name"
      expect(test.age).to be_nil
    end
  end

  context "with a before_save method" do
    before :all do
      class ::BeforeSaveTest < ::HookTest
        before_save :update_age

        def update_age
          self.age = 15
        end
      end
    end

    it "calls the before_save method before saving" do
      test = subject.as(::BeforeSaveTest)
      expect(test.age).to be_nil
      test.save
      expect(test.age).to eql 15
      expect(repository).to have_statement RDF::Statement(subject, RDF::FOAF.age, 15)
    end
  end

  context "with an after_save method" do

    before :all do
      class ::AfterSaveTest < ::HookTest
        after_save :update_age

        def update_age
          self.age = 15
        end
      end
    end

    it "calls the after_save method after saving" do
      test = subject.as(::AfterSaveTest)
      expect(test.age).to be_nil
      test.save
      expect(test.age).to eql 15
      expect(repository).not_to have_statement RDF::Statement(subject, RDF::FOAF.age, 15)
    end

  end

  context "with a before_destroy method" do
    before :all do
      class ::BeforeDestroyTest < ::HookTest
        before_destroy :cleanup

        def cleanup
          self.class.repository.delete(RDF::Statement.new(nil,RDF::FOAF.nick,nil))
        end
      end
    end

    before {repository << RDF::Statement.new(RDF::URI('http://example.org/new'), RDF::FOAF.nick, "test")}

    it "calls the before_destroy method before destroying" do
      subject.as(::BeforeDestroyTest).destroy(:completely)
      expect(repository).to be_empty
    end
  end

  context "with an after_destroy method" do
    before :all do
      class ::AfterDestroyTest < ::HookTest
        after_destroy :cleanup

        def cleanup
          self.class.repository.delete(RDF::Statement.new(nil,RDF::FOAF.nick,nil))
          raise Exception if self.class.repository.has_subject?(self.subject)
        end
      end
    end

    before {repository << RDF::Statement.new(RDF::URI('http://example.org/new'), RDF::FOAF.nick, "test")}

    it "calls the after_destroy method after destroying" do
      # This would raise an exception if after_destroy were called before deleting is confirmed
      expect { subject.as(::AfterDestroyTest).destroy(:completely) }.not_to raise_error
      # This one makes sure that after_destory got called at all
      expect(repository).not_to have_predicate RDF::FOAF.nick
    end
  end

  context "when the hook methods are private" do
    before :all do
      class Counter
        class << self
          attr_accessor :called_methods
        end
        self.called_methods = Set.new
      end

      class ::PrivateHookTest < ::HookTest
        type FOAF.Person

        before_create :add_bc_counter
        after_create :add_ac_counter

        before_save :add_bs_counter
        after_save :add_as_counter

        before_destroy :add_bd_counter
        after_destroy :add_ad_counter

        before_update :add_bu_counter
        after_update :add_au_counter

        private

        def add_counter(name)
          Counter.called_methods << name.to_s
        end
        def add_bc_counter
          add_counter(__method__)
        end
        def add_ac_counter
          add_counter(__method__)
        end
        def add_bs_counter
          add_counter(__method__)
        end
        def add_as_counter
          add_counter(__method__)
        end
        def add_bd_counter
          add_counter(__method__)
        end
        def add_ad_counter
          add_counter(__method__)
        end
        def add_bu_counter
          add_counter(__method__)
        end
        def add_au_counter
          add_counter(__method__)
        end
      end
    end

    before {repository << RDF::Statement.new(subject, RDF.type, RDF::FOAF.Person)}

    it "should call the hook methods" do
      subject = RDF::URI.new('http://example.org/test1').as(::PrivateHookTest)

      subject.save
      subject.update_attributes(:name => "Jay")
      subject.destroy

      expect(Counter.called_methods).to include "add_bc_counter"
      expect(Counter.called_methods).to include "add_ac_counter"
      expect(Counter.called_methods).to include "add_bu_counter"
      expect(Counter.called_methods).to include "add_au_counter"
      expect(Counter.called_methods).to include "add_bs_counter"
      expect(Counter.called_methods).to include "add_as_counter"
      expect(Counter.called_methods).to include "add_bd_counter"
      expect(Counter.called_methods).to include "add_ad_counter"
    end
  end
end
