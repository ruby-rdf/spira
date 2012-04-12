require "spec_helper"

describe 'A Spira resource' do

  before :all do
    class ::Bank < Spira::Base
      configure :default_vocabulary => RDF::URI.new('http://example.org/banks/vocab')

      property :title, :predicate => RDFS.label
      property :balance, :type => Integer

      validate :validate_bank

      def validate_bank
        errors.add(:title, "must not be blank") if title.blank?
        errors.add(:balance, "must be a number") unless balance.is_a?(Numeric)
      end
    end

    Spira.add_repository(:default, RDF::Repository.new)
  end

  context "when validating" do

    before :all do
      class ::V2 < Spira::Base
        property :title, :predicate => DC.title
        validate :title_is_bad

        def title_is_bad
          errors.add(:title, "is not xyz") unless title == "xyz"
        end
      end
    end

    before :each do
      @uri = RDF::URI.intern('http://example.org/bank1')
      @uri2 = RDF::URI.intern('http://example.org/bank2')
      @valid = V2.for(@uri, :title => 'xyz')
      @invalid = V2.for(@uri, :title => 'not xyz')
    end

    context "with #validate" do
      it "returns true when the model is valid" do
        @valid.should be_valid
      end

      it "returns an empty errors object after validating when the model is valid" do
        @valid.valid?
        @valid.errors.should be_empty
      end

      it "returns false when the model is invalid" do
        @invalid.should_not be_valid
      end

      it "returns an errors object with errors after validating when the model is invalid" do
        @invalid.valid?
        @invalid.errors.should_not be_empty
      end
    end

    context "an invalid model" do
      before :each do
        @uri2 = RDF::URI.intern('http://example.org/bank2')
        @invalid = V2.for(@uri, :title => 'not xyz')
        @invalid.valid?
      end

      it "returns a non-empty errors object afterwards" do
        @invalid.errors.should_not be_empty
      end

      it "has an error for an invalid field" do
        @invalid.errors[:title].should_not be_empty
      end

      it "has the correct error string for the invalid field" do
        @invalid.errors[:title].first.should == 'is not xyz'
      end

    end
  end

  context "when saving with validations, " do
    it "does not save an invalid model" do
      bank = Bank.for RDF::URI.new('http://example.org/banks/bank1')
      lambda { bank.save! }.should raise_error Spira::RecordInvalid
    end

    it "saves a valid model" do
      bank = Bank.for RDF::URI.new('http://example.org/banks/bank1')
      bank.title = "A bank"
      bank.balance = 1000
      lambda { bank.save! }.should_not raise_error
    end
  end

  context "using the included validation" do
    describe "validates_inclusion_of" do

      before :all do
        class ::V1 < Spira::Base
          property :title, :predicate => DC.title
          validates_inclusion_of :title, :in => ["xyz"]
        end
      end

      before :each do
        @v1 = V1.for RDF::URI.new('http://example.org/v1/first')
      end

      it "does not save when the assertion is false" do
        @v1.title = 'abc'
        lambda { @v1.save! }.should raise_error Spira::RecordInvalid
      end

      it "saves when the assertion is true" do
        @v1.title = 'xyz'
        lambda { @v1.save! }.should_not raise_error
      end
    end

    describe "validates_uniqueness_of" do
      before :all do
        class ::V4 < Spira::Base
          property :name, :predicate => DC.title
          validates_uniqueness_of :name
        end
      end

      before do
        v1 = V4.for RDF::URI.new('http://example.org/v2/first')
        v1.name = "unique name"
        v1.save
      end

      it "should have errors on :name" do
        v2 = V4.for RDF::URI.new('http://example.org/v2/second')
        v2.name = "unique name"
        v2.save
        v2.errors[:name].should_not be_empty
      end

      it "should have no errors on :name" do
        v3 = V4.for RDF::URI.new('http://example.org/v2/second')
        v3.name = "another name"
        v3.save
        v3.errors[:name].should be_empty
      end
    end

    describe "validates_presence_of" do
      before :all do
        class ::V2 < Spira::Base
          property :title, :predicate => DC.title
          validates_presence_of :title
        end
      end

      before :each do
        @v2 = V2.for RDF::URI.new('http://example.org/v2/first')
      end

      it "does not save when the field is nil" do
        lambda { @v2.save! }.should raise_error Spira::RecordInvalid
      end

      it "saves when the field is not nil" do
        @v2.title = 'xyz'
        lambda { @v2.save! }.should_not raise_error Spira::RecordInvalid
      end
    end

    describe "validates_numericality_of" do
      before :all do
        class ::V3 < Spira::Base
          property :title, :predicate => DC.title, :type => Integer
          validates_numericality_of :title
        end
      end

      before :each do
        @v3 = V3.for RDF::URI.new('http://example.org/v3/first')
      end

      it "does not save when the field is nil" do
        lambda { @v3.save! }.should raise_error Spira::RecordInvalid
      end

      it "does not save when the field is not numeric" do
        @v3.title = 'xyz'
        lambda { @v3.save! }.should raise_error Spira::RecordInvalid
      end

      it "saves when the field is numeric" do
        @v3.title = 15
        lambda { @v3.save! }.should_not raise_error
      end
    end
  end

end
