require "spec_helper"

describe Spira::Utils do

  describe "rename!" do
    it "TODO: adapt to Spira::Utils.rename!"

    # before :each do
    #   @new_uri = RDF::URI('http://example.org/people/test2')
    #   @other_uri = RDF::URI('http://example.org/people/test3')
    #   @update_repo << RDF::Statement.new(@test_uri, RDF::FOAF.name, 'Not in model')
    #   @update_repo << RDF::Statement.new(@other_uri, RDF::RDFS.seeAlso, @test_uri)
    #   @name = @test.name
    #   @age = @test.age
    # end

    # context "with #rename!" do
    #   it "supports #rename!" do
    #     expect(@test.respond_to?(:rename!)).to be_truthy
    #   end

    #   it "copies model data to a given subject" do
    #     new = @test.rename!(@new_uri)
    #     expect(new.name).to eql @name
    #     expect(new.age).to eql @age
    #   end

    #   it "updates references to the old subject as objects" do
    #     new = @test.rename!(@new_uri)
    #     expect(@update_repo).to have_statement RDF::Statement.new(@other_uri, RDF::RDFS.seeAlso, @new_uri)
    #     expect(@update_repo).not_to have_statement RDF::Statement.new(@other_uri, RDF::RDFS.seeAlso, @test_uri)
    #   end

    #   it "saves the copy immediately" do
    #     @test.rename!(@new_uri)
    #     expect(@update_repo).to have_statement RDF::Statement.new(@new_uri, RDF::RDFS.label, @name)
    #     expect(@update_repo).to have_statement RDF::Statement.new(@new_uri, RDF::FOAF.age, @age)
    #   end

    #   it "deletes the old model data" do
    #     @test.rename!(@new_uri)
    #     expect(@update_repo).not_to have_statement RDF::Statement.new(@test_uri, RDF::RDFS.label, @name)
    #     expect(@update_repo).not_to have_statement RDF::Statement.new(@test_uri, RDF::FOAF.age, @age)
    #   end

    #   it "copies non-model data to the given subject" do
    #     new = @test.rename!(@new_uri)
    #     expect(@update_repo).to have_statement RDF::Statement.new(@new_uri, RDF::FOAF.name, 'Not in model')
    #   end

    #   it "deletes all data about the old subject" do
    #     new = @test.rename!(@new_uri)
    #     @update_repo.query(:subject => @test_uri).size.should == 0
    #     @update_repo.query(:object => @test_uri).size.should == 0
    #   end
    # end
  end

end
