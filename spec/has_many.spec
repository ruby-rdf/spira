require File.dirname(File.expand_path(__FILE__)) + '/spec_helper'

class Posts < RDF::Vocabulary('http://example.org/posts/predicates/')
  property :rating
end

describe "has_many" do

  before :all do
    require 'rdf/ntriples'
    class ::Post < Spira::Base

      type URI.new('http://rdfs.org/sioc/types#Post')

      has_many :comments, :predicate => SIOC.has_reply, :type => :Comment
      property :title,    :predicate => DC.title
      property :body,     :predicate => SIOC.content

    end



    class ::Comment < Spira::Base

      type URI.new('http://rdfs.org/sioc/types#Comment')

      property :post,     :predicate => SIOC.reply_of, :type => :Post
      property :title,    :predicate => DC.title
      property :body,     :predicate => SIOC.content
      has_many :ratings,  :predicate => Posts.rating, :type => Integer

    end
  end

  context "Comment class basics" do
    before :each do
      @posts_repository = RDF::Repository.load(fixture('has_many.nt'))
      Spira.add_repository(:default, @posts_repository)
      @uri = RDF::URI.new('http://example.org/comments/comment1')
      @empty_uri = RDF::URI.new('http://example.org/comments/comment0')
      @comment = Comment.for @uri
      @empty_comment = Comment.for @empty_uri
    end

    it "should have a ratings method" do
      @comment.should respond_to :ratings
    end

    it "should having a ratings= method" do
      @comment.should respond_to :ratings=
    end

    it "should support is_list?" do
      Comment.should respond_to :is_list?
    end

    it "should report that ratings are a list" do
      Comment.is_list?(:ratings).should == true
    end

    it "should report that bodies are not a list" do
      Comment.is_list?(:body).should == false
    end

    it "should return an empty array of ratings for comments with none" do
      @empty_comment.ratings.should == Set.new
    end

    it "should return a set of ratings for comments with some" do
      @comment.ratings.should be_a Set
      @comment.ratings.size.should == 3
      @comment.ratings.sort.should == [1,3,5]
    end

    it "should allow setting and saving non-array elements" do
      @comment.title = 'test'
      @comment.title.should == 'test'
      @comment.save!
      @comment.title.should == 'test'
    end

    it "should allow setting on array elements" do
      @comment.ratings = [1,2,4]
      @comment.save!
      @comment.ratings.sort.should == [1,2,4]
    end

    it "should allow saving array elements" do
      @comment.ratings = [1,2,4]
      @comment.ratings.sort.should == [1,2,4]
      @comment.save!
      @comment.ratings.sort.should == [1,2,4]
      @comment = Comment.for @uri
      @comment.ratings.sort.should == [1,2,4]
    end

    it "should allow appending to array elements" do
      @comment.ratings << 6
      @comment.ratings.sort.should == [1,3,5,6]
      @comment.save!
      @comment.ratings.sort.should == [1,3,5,6]
    end

    it "should allow saving of appended elements" do
      @comment.ratings << 6
      @comment.save!
      @comment = Comment.for @uri
      @comment.ratings.sort.should == [1,3,5,6]
    end
  end

  context "Post class basics" do
    before :all do
      @posts_repository = RDF::Repository.load(fixture('has_many.nt'))
      Spira.add_repository(:default, @posts_repository)
    end

    before :each do
      @uri = RDF::URI.new('http://example.org/posts/post1')
      @empty_uri = RDF::URI.new('http://example.org/posts/post0')
      @post = Post.for @uri
      @empty_post = Post.for @empty_uri
      @empty_comment_uri = RDF::URI.new('http://example.org/comments/comment0')
      @empty_comment = Comment.for @empty_comment_uri
    end

    it "should have a comments method" do
      @post.should respond_to :comments
    end

    it "should have a comments= method" do
      @post.should respond_to :comments=
    end

    it "should return an empty array from comments for an object with none" do
      @empty_post.comments.should == Set.new
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
      @post.comments.size.should == 3
      @post.save!
      @post.comments.size.should == 3
      @post.comments.each do |comment|
	comments.should include comment
      end
    end
  end




end
