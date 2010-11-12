require File.dirname(File.expand_path(__FILE__)) + '/spec_helper'

describe Spira do

  before :all do
    class ::Bank
    
      include Spira::Resource
    
      default_vocabulary URI.new('http://example.org/banks/vocab')
    
      property :title, :predicate => RDFS.label
      property :balance, :type => Integer

      validate :validate_bank
      
      def validate_bank
        assert_set :title
        assert_numeric :balance
      end
    
    end
    Spira.add_repository(:default, RDF::Repository.new)
  end

  context "when saving with validations, " do
    it "does not save an invalid model" do
      bank = Bank.for RDF::URI.new('http://example.org/banks/bank1')
      lambda { bank.save! }.should raise_error Spira::ValidationError
    end

    it "saves a valid model" do
      bank = Bank.for RDF::URI.new('http://example.org/banks/bank1')
      bank.title = "A bank"
      bank.balance = 1000
      lambda { bank.save! }.should_not raise_error
    end
  end

  context "using the included validation" do
    context "assert, " do

      before :all do
        class ::V1
          include Spira::Resource
          property :title, :predicate => DC.title
          validate :title_is_bad
          def title_is_bad
            assert(title == 'xyz', :title, 'bad title')
          end
        end
      end

      before :each do
        @v1 = V1.for RDF::URI.new('http://example.org/v1/first')
      end 

      it "does not save when the assertion is false" do
        @v1.title = 'abc'
        lambda { @v1.save! }.should raise_error Spira::ValidationError
      end

      it "saves when the assertion is true" do
        @v1.title = 'xyz'
        lambda { @v1.save! }.should_not raise_error
      end

    end

    context "assert_set, " do
      before :all do
        class ::V2
          include Spira::Resource
          property :title, :predicate => DC.title
          validate :title_is_set
          def title_is_set
            assert_set(:title)
          end
        end
      end

      before :each do
        @v2 = V2.for RDF::URI.new('http://example.org/v2/first')
      end 

      it "does not save when the field is nil" do
        lambda { @v2.save! }.should raise_error Spira::ValidationError
      end

      it "saves when the field is not nil" do
        @v2.title = 'xyz'
        lambda { @v2.save! }.should_not raise_error Spira::ValidationError
      end

    end

    context "assert_numeric, " do
      before :all do
        class ::V3
          include Spira::Resource
          property :title, :predicate => DC.title, :type => Integer
          validate :title_is_numeric
          def title_is_numeric
            assert_numeric(:title)
          end
        end
      end

      before :each do
        @v3 = V3.for RDF::URI.new('http://example.org/v3/first')
      end 

      it "does not save when the field is nil" do
        lambda { @v3.save! }.should raise_error Spira::ValidationError
      end

      it "does not save when the field is not numeric" do
        @v3.title = 'xyz'
        lambda { @v3.save! }.should raise_error Spira::ValidationError
      end

      it "saves when the field is numeric" do
        @v3.title = 15
        lambda { @v3.save! }.should_not raise_error
      end
    end
  end

end
