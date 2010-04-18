require File.dirname(__FILE__) + "/spec_helper.rb"


describe 'types' do

  context "when declaring a new type" do
    before :all do
      class TypeA
        include Spira::Type
      end

      class TypeB
        include Spira::Type
        register_alias :typeb_alias
      end

      class TypeC
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
      Spira.types[TypeA].should == TypeA
    end

    it "should have a class method to serialize" do
      TypeA.should respond_to :serialize
    end

    it "should have a class method to unserialize" do
      TypeA.should respond_to :unserialize
    end

    it "should allow itself to be aliased" do
      TypeA.register_alias(:typea_alias)
      Spira.types[:typea_alias].should == TypeA
    end

    it "should allow aliases in the DSL" do
      Spira.types[:typeb_alias].should == TypeB
    end

    it "should allow a self.serialize function" do
      TypeC.serialize(5).should == "5"
    end

    it "should allow a self.unserialize function" do
      TypeC.unserialize("5").should == 5
    end

    context "working with RDF vocabularies" do
      before :all do
        class TypeWithRDF
          include Spira::Type
          register_alias DC.title
        end
      end

      it "should have the RDF namespace included for default vocabularies" do
        Spira.types[::RDF::DC.title].should == TypeWithRDF
      end
    end

  end


end

