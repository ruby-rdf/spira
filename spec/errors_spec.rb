require "spec_helper"

describe Spira::Errors do

  context "when instantiating" do

    it "should be instantiable" do
      Spira::Errors.new.should_not be_nil
    end

    it "should not have any errors to start" do
      Spira::Errors.new.should be_empty
    end

  end

  context "when adding errors" do
    before :each do
      @errors = Spira::Errors.new
    end

    it "should allow adding errors" do
      lambda {@errors.add(:field, "cannot be null")}.should_not raise_error
    end
  end

  context "when retrieving errors" do
    before :each do
      @errors = Spira::Errors.new
      @errors.add(:field, "cannot be null")
    end

    it "should not be empty" do
      @errors.should_not be_empty
    end

    it "have errors for a field with errors" do
      @errors.any_for?(:field).should be_true
    end

    it "should not have errors for a field without errors" do
      @errors.any_for?(:other).should be_false
    end

    it "should have the correct error name for a given error" do
      @errors.for(:field).should == ["cannot be null"]
    end

    it "should provide a list of all errors" do
      @errors.should respond_to :each
      @errors.each.should == ["field cannot be null"]
    end

  end

  context "when clearing errors" do
    before :each do
      @errors = Spira::Errors.new
      @errors.add(:field, "cannot be null")
    end

    it "should respond to :clear" do
      @errors.should respond_to :clear
    end

    it "should clear errors on #clear" do
      @errors.any_for?(:field).should be_true
      @errors.clear
      @errors.should be_empty
    end

  end
end
