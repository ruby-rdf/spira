require 'spira'

class Posts < RDF::Vocabulary('http://example.org/posts/predicates/')
  property :rating
end

class Post

  include Spira::Resource

  type URI.new('http://rdfs.org/sioc/types#Post')

  has_many :comments, SIOC.has_reply, :comment
  property :title, DC.title, String
  property :body, SIOC.content, String

end



class Comment

  include Spira::Resource

  type URI.new('http://rdfs.org/sioc/types#Comment')

  property :post, SIOC.reply_of, :post
  property :title, DC.title, String
  property :body, SIOC.content, String
  has_many :ratings, Posts.rating, Integer

end
