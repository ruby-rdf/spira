

# For testing assertions
#
class Bank

  include Spira::Resource

  default_vocabulary URI.new('http://example.org/banks/vocab')

  property :title, :predicate => RDFS.label
  property :balance, :type => Integer

  def validate
    assert_set :title
    assert_numeric :balance
  end

end
