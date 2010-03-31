require 'spira'

class Posts < RDF::Vocabulary('http://example.org/posts/predicates/')
  property :rating
end

class Post

  include Spira::Resource

  type URI.new('http://rdfs.org/sioc/types#Post')

  has_many :comments, :predicate => SIOC.has_reply, :type => :comment
  property :title,    :predicate => DC.title
  property :body,     :predicate => SIOC.content

end



class Comment

  include Spira::Resource

  type URI.new('http://rdfs.org/sioc/types#Comment')

  property :post,     :predicate => SIOC.reply_of, :type => :post
  property :title,    :predicate => DC.title
  property :body,     :predicate => SIOC.content
  has_many :ratings,  :predicate => Posts.rating, :type => Integer

end
