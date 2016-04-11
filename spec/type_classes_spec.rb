require "spec_helper"

describe 'types' do

  context "when declaring a new type" do
    before :all do
      class ::TypeA
        include Spira::Type
      end

      class ::TypeB
        include Spira::Type
        register_alias :typeb_alias
      end

      class ::TypeC
        include Spira::Type
        
        def self.serialize(value)
          value.to_s
        end

        def self.unserialize(value)
          value.to_i
        end
      end
    end

    it "should find itself registered as a type with spira" do
      expect(Spira.types[TypeA]).to eql TypeA
    end

    it "should have a class method to serialize" do
      expect(TypeA).to respond_to :serialize
    end

    it "should have a class method to unserialize" do
      expect(TypeA).to respond_to :unserialize
    end

    it "should allow itself to be aliased" do
      TypeA.register_alias(:typea_alias)
      expect(Spira.types[:typea_alias]).to eql TypeA
    end

    it "should allow aliases in the DSL" do
      expect(Spira.types[:typeb_alias]).to eql TypeB
    end

    it "should allow a self.serialize function" do
      expect(TypeC.serialize(5)).to eql "5"
    end

    it "should allow a self.unserialize function" do
      expect(TypeC.unserialize("5")).to eql 5
    end

    context "working with RDF vocabularies" do
      before :all do
        class ::TypeWithRDF
          include Spira::Type
          register_alias RDF::Vocab::DC.title
        end
      end

      it "should have the RDF namespace included for default vocabularies" do
        expect(Spira.types[::RDF::Vocab::DC.title]).to eql TypeWithRDF
      end
    end
  end
end

