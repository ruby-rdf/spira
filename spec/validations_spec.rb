require "spec_helper"

describe 'A Spira resource' do
  let(:uri) {RDF::URI.intern('http://example.org/bank1')}
  let(:valid) {V2.for(uri, :title => 'xyz')}
  let(:invalid) {V2.for(uri, :title => 'not xyz')}

  class ::Bank < Spira::Base
    configure :default_vocabulary => RDF::URI.new('http://example.org/banks/vocab')

    property :title, :predicate => RDF::RDFS.label
    property :balance, :type => Integer

    validate :validate_bank

    def validate_bank
      errors.add(:title, "must not be blank") if title.blank?
      errors.add(:balance, "must be a number") unless balance.is_a?(Numeric)
    end
  end

  before do
    Spira.repository = RDF::Repository.new
  end

  context "when validating" do
    class ::V2 < Spira::Base
      property :title, :predicate => RDF::Vocab::DC.title
      validate :title_is_bad

      def title_is_bad
        errors.add(:title, "is not xyz") unless title == "xyz"
      end
    end

    context "with #validate" do
      it "returns true when the model is valid" do
        expect(valid).to be_valid
      end

      it "returns an empty errors object after validating when the model is valid" do
        valid.valid?
        expect(valid.errors).to be_empty
      end

      it "returns false when the model is invalid" do
        expect(invalid).not_to be_valid
      end

      it "returns an errors object with errors after validating when the model is invalid" do
        invalid.valid?
        expect(invalid.errors).not_to be_empty
      end
    end

    context "an invalid model" do
      before :each do
        invalid.valid?
      end

      it "returns a non-empty errors object afterwards" do
        expect(invalid.errors).not_to be_empty
      end

      it "has an error for an invalid field" do
        expect(invalid.errors[:title]).not_to be_empty
      end

      it "has the correct error string for the invalid field" do
        expect(invalid.errors[:title].first).to eql 'is not xyz'
      end

    end
  end

  context "when saving with validations, " do
    it "does not save an invalid model" do
      bank = Bank.for RDF::URI.new('http://example.org/banks/bank1')
      expect { bank.save! }.to raise_error Spira::RecordInvalid
    end

    it "saves a valid model" do
      bank = Bank.for RDF::URI.new('http://example.org/banks/bank1')
      bank.title = "A bank"
      bank.balance = 1000
      expect { bank.save! }.not_to raise_error
    end
  end

  context "using the included validation" do
    describe "validates_inclusion_of" do

      before :all do
        class ::V1 < Spira::Base
          property :title, :predicate => RDF::Vocab::DC.title
          validates_inclusion_of :title, :in => ["xyz"]
        end
      end

      let(:v1) {V1.for RDF::URI.new('http://example.org/v1/first')}

      it "does not save when the assertion is false" do
        v1.title = 'abc'
        expect { v1.save! }.to raise_error Spira::RecordInvalid
      end

      it "saves when the assertion is true" do
        v1.title = 'xyz'
        expect { v1.save! }.not_to raise_error
      end
    end

    describe "validates_uniqueness_of" do
      before :all do
        class ::V4 < Spira::Base
          type RDF::Vocab::FOAF.Person
          property :name, :predicate => RDF::Vocab::DC.title
          validates_uniqueness_of :name
        end
      end

      before do
        v1 = V4.for RDF::URI.new('http://example.org/v2/first')
        v1.name = "unique name"
        v1.save
      end

      it "should not have errors on name for the same record" do
        v1 = V4.for RDF::URI.new('http://example.org/v2/first')
        v1.name = v1.name
        v1.save
        expect(v1.errors[:name]).to be_empty
      end

      it "should have errors on :name" do
        v2 = V4.for RDF::URI.new('http://example.org/v2/second')
        v2.name = "unique name"
        v2.save
        expect(v2.errors[:name]).not_to be_empty
      end

      it "should have no errors on :name" do
        v3 = V4.for RDF::URI.new('http://example.org/v2/second')
        v3.name = "another name"
        v3.save
        expect(v3.errors[:name]).to be_empty
      end
    end

    describe "validates_presence_of" do
      before :all do
        class ::V2 < Spira::Base
          property :title, :predicate => RDF::Vocab::DC.title
          validates_presence_of :title
        end
      end

      let(:v2) {V2.for RDF::URI.new('http://example.org/v2/first')}

      it "does not save when the field is nil" do
        expect { v2.save! }.to raise_error Spira::RecordInvalid
      end

      it "saves when the field is not nil" do
        v2.title = 'xyz'
        expect { v2.save! }.not_to raise_error
      end
    end

    describe "validates_numericality_of" do
      before :all do
        class ::V3 < Spira::Base
          property :title, :predicate => RDF::Vocab::DC.title, :type => Integer
          validates_numericality_of :title
        end
      end

      let(:v3) {V3.for RDF::URI.new('http://example.org/v3/first')}

      it "does not save when the field is nil" do
        expect { v3.save! }.to raise_error Spira::RecordInvalid
      end

      it "does not save when the field is not numeric" do
        v3.title = 'xyz'
        expect { v3.save! }.to raise_error Spira::RecordInvalid
      end

      it "saves when the field is numeric" do
        v3.title = 15
        expect { v3.save! }.not_to raise_error
      end
    end
  end

end
