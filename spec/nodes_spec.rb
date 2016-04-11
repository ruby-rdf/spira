require "spec_helper"

# Behaviors relating to BNodes vs URIs

describe 'Spira resources' do

  before :all do
    class ::NodeTest < Spira::Base
      property :name, :predicate => RDF::Vocab::FOAF.name
    end
  end

  before :each do
    Spira.clear_repository!
    Spira.repository = RDF::Repository.new
  end

  context "when instatiated from URIs" do
    let(:uri) {RDF::URI('http://example.org/bob')}
    subject {uri.as(NodeTest)}

    it {is_expected.to respond_to :to_uri}

    it {is_expected.not_to respond_to :to_node}

    its(:node?) {is_expected.to be_falsey}
    its(:to_uri) {is_expected.to eql uri}

    specify {expect { subject.to_node }.to raise_error NoMethodError}
  end

  context "when instantiated from Nodes" do
    let(:node) {RDF::Node.new}
    subject {node.as(NodeTest)}
    
    it {is_expected.not_to respond_to :to_uri}

    it {is_expected.to respond_to :to_node}

    its(:node?) {is_expected.to be_truthy}
    its(:to_node) {is_expected.to eql node}

    specify {expect { subject.to_uri }.to raise_error NoMethodError}
  end
end
