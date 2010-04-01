require File.dirname(__FILE__) + "/spec_helper.rb"

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


describe "has_many" do

  before :all do
    require 'rdf/ntriples'
    @posts_repository = RDF::Repository.load(fixture('has_many.nt'))
    Spira.add_repository(:default, @posts_repository)
  end

  context "Comment class basics" do
    before :each do
      @uri = RDF::URI.new('http://example.org/comments/comment1')
      @empty_uri = RDF::URI.new('http://example.org/comments/comment0')
      @comment = Comment.find @uri
      @empty_comment = Comment.create @empty_uri
    end

    it "should have a ratings method" do
      @comment.should respond_to :ratings      
    end

    it "should having a ratings= method" do
      @comment.should respond_to :ratings=
    end

    it "should return an empty array of ratings for comments with none" do
      @empty_comment.ratings.should == []
    end

    it "should return an array of ratings for comments with some" do
      @comment.ratings.should == [1,3,5]
    end

    it "should allow setting and saving non-array elements" do
      @comment.title = 'test'
      @comment.title.should == 'test'
      @comment.save!
      @comment.title.should == 'test'
    end

    it "should allow setting on array elements" do
      @comment.ratings = [1,2,4]
      @comment.ratings.should == [1,2,4]
    end

    it "should allow appending to array elements" do
      pending "Requires proxy object magic.  Need to study implications"
      @comment.ratings << 5
      @comment.ratings.should == [1,3,5,5]
    end

    it "should allow saving array elements" do
      @comment.ratings = [1,2,4]
      @comment.ratings.should == [1,2,4]
      @comment.save!
      @comment.ratings.should == [1,2,4]
    end
  end

  context "Post class basics" do
    before :each do
      @uri = RDF::URI.new('http://example.org/posts/post1')
      @empty_uri = RDF::URI.new('http://example.org/posts/post0')
      @post = Post.find @uri
      @empty_post = Post.create @empty_uri
      @empty_comment_uri = RDF::URI.new('http://example.org/comments/comment0')
      @empty_comment = Comment.create @empty_comment_uri
    end

    it "should have a comments method" do
      @post.should respond_to :comments
    end

    it "should have a comments= method" do
      @post.should respond_to :comments=
    end

    it "should return an empty array from comments for an object with none" do
      @empty_post.comments.should == []
    end

    it "should return an array of comments for an object with some" do
      @post.comments.size.should == 2
      @post.comments.each do |comment|
        comment.should be_a Comment
      end
    end

    it "should allow setting and saving non-array elements" do
      @post.title = "test post title"
      @post.save!
      @post.title.should == 'test post title'
    end

    it "should allow setting array elements" do
      @post.comments = (@post.comments + [@empty_comment])
      @post.comments.size.should == 3
      @post.comments.should include @empty_comment
    end

    it "should allow saving array elements" do
      comments = @post.comments + [@empty_comment]
      @post.comments = (@post.comments + [@empty_comment])
      @post.save!
      @post.comments.size.should == 3
      @post.comments.each do |comment|
        comments.should include comment
      end
    end
  end
  



end
