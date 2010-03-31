require File.dirname(__FILE__) + "/spec_helper.rb"


describe 'types for properties' do

  before :all do
    require 'property_types'
  end

  context 'when ruby types are specified' do
    context "appropriate XSD datatype for a set property" do
      
      before :each do
        @resource = RubyProps.create 'test'
      end

      context "it uses XSD.integer for Integer" do
        it "saves a fixnum as an XSD.integer" do
          @resource.integer = 15
          @resource.should have_object RDF::Literal.new(15)
        end
    
        it "typecasts strings to integers" do
          pending "Tough call.  typecasting is an implicit validation, and of course ruby's to_i on a string => 0 doesn't help."
          @resource.integer = "15"
          @resource.should have_object RDF::Literal.new(15)
        end

      end
    end
  end

  context 'when XSD types are specified' do

  end



end
