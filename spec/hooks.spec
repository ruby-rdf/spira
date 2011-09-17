require File.dirname(File.expand_path(__FILE__)) + '/spec_helper'

describe 'Spira resources' do

  before :all do
    class ::HookTest < ::Spira::Base
      property :name, :predicate => FOAF.name
      property :age,  :predicate => FOAF.age
    end
    @subject = RDF::URI.intern('http://example.org/test')
  end

  before :each do
    @repository = RDF::Repository.new
    @repository << RDF::Statement.new(@subject, RDF::FOAF.name, "A name")
    Spira.add_repository(:default, @repository)
  end

  context "with a before_create method" do
    before :all do
      class ::BeforeCreateTest < ::HookTest
        type FOAF.bc_test

       def before_create
          self.name = "Everyone has this name"
        end
      end

      class ::BeforeCreateWithoutTypeTest < ::HookTest
        def before_create
          self.name = "Everyone has this name"
        end
      end
    end

    before :each do
      @repository << RDF::Statement.new(@subject, RDF.type, RDF::FOAF.bc_test)
    end

    it "calls the before_create method before saving a resouce for the first time" do
      test = RDF::URI('http://example.org/new').as(::BeforeCreateTest)
      test.save!
      test.name.should == "Everyone has this name"
      @repository.should have_statement RDF::Statement.new(test.subject, RDF::FOAF.name, "Everyone has this name")
    end

    it "does not call the before_create method if the resource previously existed" do
      test = @subject.as(::BeforeCreateTest)
      test.save!
      test.name.should == "A name"
      @repository.should have_statement RDF::Statement.new(test.subject, RDF::FOAF.name, "A name")
      @repository.should_not have_statement RDF::Statement.new(test.subject, RDF::FOAF.name, "Everyone has this name")
    end

    it "does not call the before_create method without a type declaration" do
      test = RDF::URI('http://example.org/new').as(::BeforeCreateWithoutTypeTest)
      test.save!
      @repository.should_not have_statement RDF::Statement.new(test.subject, RDF::FOAF.name, "Everyone has this name")
    end
  end

  context "with an after_create method" do
    before :all do
      class ::AfterCreateTest < ::HookTest
        type FOAF.ac_test

       def after_create
          self.name = "Everyone has this unsaved name"
        end
      end

      class ::AfterCreateWithoutTypeTest < ::HookTest
        def after_create
          self.name = "Everyone has this unsaved name"
        end
      end
    end

    before :each do
      @repository << RDF::Statement.new(@subject, RDF.type, RDF::FOAF.bc_test)
    end

    it "calls the after_create method after saving a resource for the first time" do
      test = RDF::URI('http://example.org/new').as(::AfterCreateTest)
      test.save!
      test.name.should == "Everyone has this unsaved name"
      @repository.should_not have_statement RDF::Statement.new(test.subject, RDF::FOAF.name, "Everyone has this name")
    end

    it "does not call after_create if the resource previously existed" do
      test = @subject.as(::AfterCreateTest)
      test.save!
      test.name.should == "A name"
      @repository.should have_statement RDF::Statement.new(test.subject, RDF::FOAF.name, "A name")
      @repository.should_not have_statement RDF::Statement.new(test.subject, RDF::FOAF.name, "Everyone has this name")
    end

    it "does not call the after_create method without a type declaration" do
      test = RDF::URI('http://example.org/new').as(::AfterCreateWithoutTypeTest)
      test.save!
      test.name.should be_nil
    end
  end

  context "with an after_update method" do

    before :all do
      class ::AfterUpdateTest < ::HookTest
        def after_update
          self.age = 15
        end
      end
    end

    it "calls the after_update method after updating a field" do
      test = @subject.as(AfterUpdateTest)
      test.age.should be_nil
      test.update(:name => "A new name")
      test.age.should == 15
    end

    it "does not call the after_update method after simply setting a field" do
      test = @subject.as(AfterUpdateTest)
      test.age.should be_nil
      test.name = "a new name"
      test.age.should be_nil
    end
  end

  context "with a before_save method" do
    before :all do
      class ::BeforeSaveTest < ::HookTest
        def before_save
          self.age = 15
        end
      end
    end

    it "calls the before_save method before saving" do
      test = @subject.as(::BeforeSaveTest)
      test.age.should be_nil
      test.save!
      test.age.should == 15
      @repository.should have_statement RDF::Statement(@subject, RDF::FOAF.age, 15)
    end
  end

  context "with an after_save method" do

    before :all do
      class ::AfterSaveTest < ::HookTest
        def after_save
          self.age = 15
        end
      end
    end
 
    it "calls the after_save method after saving" do
      test = @subject.as(::AfterSaveTest)
      test.age.should be_nil
      test.save!
      test.age.should == 15
      @repository.should_not have_statement RDF::Statement(@subject, RDF::FOAF.age, 15)
    end

  end

  context "with a before_destroy method" do
    before :all do
      class ::BeforeDestroyTest < ::HookTest
        def before_destroy
          self.class.repository.delete(RDF::Statement.new(nil,RDF::FOAF.other,nil))
        end
      end
    end

    before :each do
      @repository << RDF::Statement.new(RDF::URI('http://example.org/new'), RDF::FOAF.other, "test")
    end

    it "calls the before_destroy method before destroying" do
      @subject.as(::BeforeDestroyTest).destroy!(:completely)
      @repository.should be_empty
    end
  end

  context "with an after_destroy method" do
    before :all do
      class ::AfterDestroyTest < ::HookTest
        def after_destroy
          self.class.repository.delete(RDF::Statement.new(nil,RDF::FOAF.other,nil))
          raise Exception if self.class.repository.has_subject?(self.subject)
        end
      end
    end

    before :each do
      @repository << RDF::Statement.new(RDF::URI('http://example.org/new'), RDF::FOAF.other, "test")
    end

    it "calls the after_destroy method after destroying" do
      # This would raise an exception if after_destroy were called before deleting is confirmed
      lambda { @subject.as(::AfterDestroyTest).destroy!(:completely) }.should_not raise_error
      # This one makes sure that after_destory got called at all
      @repository.should_not have_predicate RDF::FOAF.other
    end
  end

  context "when the hook methods are private" do
    before :all do
      class ::PrivateHookTest < ::HookTest
        type FOAF.bc_test

        def counter
          @counter ||= {}
        end

        private

        def before_create
          self.counter[__method__] = true
        end

        def before_save
          self.counter[__method__] = true
        end

        def before_destroy
          self.counter[__method__] = true
        end

        def after_create
          self.counter[__method__] = true
        end

        def after_save
          self.counter[__method__] = true
        end

        def after_update
          self.counter[__method__] = true
        end

        def after_destroy
          self.counter[__method__] = true
        end
      end
    end

    before :each do
      @repository << RDF::Statement.new(@subject, RDF.type, RDF::FOAF.bc_test)
    end

    it "should call the hook methods" do
      subject = RDF::URI.new('http://example.org/test1').as(::PrivateHookTest)

      subject.save!
      subject.update!(:name => "Jay")
      subject.destroy!

      subject.counter.keys.count.should eql(7)
    end
  end
end
