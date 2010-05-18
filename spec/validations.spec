require File.dirname(__FILE__) + "/spec_helper.rb"

describe 'validations' do

  before :all do
    class Bank
    
      include Spira::Resource
    
      default_vocabulary URI.new('http://example.org/banks/vocab')
    
      property :title, :predicate => RDFS.label
      property :balance, :type => Integer

      validate :validate_bank
      
      def validate_bank
        puts "validing bank"
        assert_set :title
        assert_numeric :balance
      end
    
    end
    Spira.add_repository(:default, RDF::Repository.new)
  end

  context "when validating" do
    it "should not save an invalid model" do
      bank = Bank.for RDF::URI.new('http://example.org/banks/bank1')
      lambda { bank.save! }.should raise_error Spira::ValidationError
    end

    it "should save a valid model" do
      bank = Bank.for RDF::URI.new('http://example.org/banks/bank1')
      bank.title = "A bank"
      bank.balance = 1000
    end

  end

  context "included validations" do
    context "provides a working assert" do

      before :all do
        class V1
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

      it "should fail when false" do
        @v1.title = 'abc'
        lambda { @v1.save! }.should raise_error Spira::ValidationError
      end

      it "should pass when true" do
        @v1.title = 'xyz'
        lambda { @v1.save! }.should_not raise_error Spira::ValidationError
      end

    end

    context "provides a working assert_set" do
      before :all do
        class V2
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

      it "should fail when nil" do
        lambda { @v2.save! }.should raise_error Spira::ValidationError
      end

      it "should pass when set" do
        @v2.title = 'xyz'
        lambda { @v2.save! }.should_not raise_error Spira::ValidationError
      end

    end

    context "provides a working assert_numeric" do
      before :all do
        class V3
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

      it "should fail when nil" do
        lambda { @v3.save! }.should raise_error Spira::ValidationError
      end

      it "should fail when non-numeric" do
        @v3.title = 'xyz'
        lambda { @v3.save! }.should raise_error Spira::ValidationError
      end

      it "should pass when numeric" do
        @v3.title = 15
        lambda { @v3.save! }.should_not raise_error Spira::ValidationError
      end

    end

  end

end
