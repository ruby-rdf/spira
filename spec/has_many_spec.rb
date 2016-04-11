require "spec_helper"

class Posts < RDF::Vocabulary('http://example.org/posts/predicates/')
  property :rating
end

describe "has_many" do

  before :all do
    class ::Post < Spira::Base
      type RDF::URI.new('http://rdfs.org/sioc/types#Post')

      has_many :comments, :predicate => RDF::Vocab::SIOC.has_reply, :type => :Comment
      property :title,    :predicate => RDF::Vocab::DC.title
      property :body,     :predicate => RDF::Vocab::SIOC.content
    end

    class ::Comment < Spira::Base
      type RDF::URI.new('http://rdfs.org/sioc/types#Comment')

      property :post,     :predicate => RDF::Vocab::SIOC.reply_of, :type => :Post
      property :title,    :predicate => RDF::Vocab::DC.title
      property :body,     :predicate => RDF::Vocab::SIOC.content
      has_many :ratings,  :predicate => Posts.rating, :type => Integer
    end
  end

  context "Comment class basics" do
    let(:url) {RDF::URI.new('http://example.org/comments/comment1')}
    let(:comment) {Comment.for url}
    let(:empty_comment) {Comment.for RDF::URI.new('http://example.org/comments/comment0')}
    before {Spira.repository = RDF::Repository.load(fixture('has_many.nt'))}

    it "should have a ratings method" do
      expect(comment).to respond_to :ratings
    end

    it "should having a ratings= method" do
      expect(comment).to respond_to :ratings=
    end

    it "should report that ratings is an association" do
      expect(Comment.reflect_on_association(:ratings)).to be_a AssociationReflection
    end

    it "should report that bodies are not a list" do
      expect(Comment.reflect_on_association(:body)).to be_nil
    end

    it "should return an empty array of ratings for comments with none" do
      expect(empty_comment.ratings).to eql []
    end

    it "should return a set of ratings for comments with some" do
      expect(comment.ratings).to be_a Array
      expect(comment.ratings.size).to eql 3
      expect(comment.ratings.sort).to eql [1,3,5]
    end

    it "should allow setting and saving non-array elements" do
      comment.title = 'test'
      expect(comment.title).to eql 'test'
      comment.save!
      expect(comment.title).to eql 'test'
    end

    it "should allow setting on array elements" do
      comment.ratings = [1,2,4]
      comment.save!
      expect(comment.ratings.sort).to eql [1,2,4]
    end

    it "should allow saving array elements" do
      comment.ratings = [1,2,4]
      expect(comment.ratings.sort).to eql [1,2,4]
      comment.save!
      expect(comment.ratings.sort).to eql [1,2,4]
      comment = Comment.for url
      expect(comment.ratings.sort).to eql [1,2,4]
    end

    it "should allow appending to array elements" do
      comment.ratings << 6
      expect(comment.ratings.sort).to eql [1,3,5,6]
      comment.save!
      expect(comment.ratings.sort).to eql [1,3,5,6]
    end

    it "should allow saving of appended elements" do
      comment.ratings << 6
      comment.save!
      comment = Comment.for url
      expect(comment.ratings.sort).to eql [1,3,5,6]
    end
  end

  context "Post class basics" do
    before :all do
      Spira.repository = RDF::Repository.load(fixture('has_many.nt'))
    end
    let(:post) {Post.for RDF::URI.new('http://example.org/posts/post1')}
    let(:empty_post) {Post.for RDF::URI.new('http://example.org/posts/post0')}
    let(:empty_comment) {Comment.for RDF::URI.new('http://example.org/comments/comment0')}

    it "should have a comments method" do
      expect(post).to respond_to :comments
    end

    it "should have a comments= method" do
      expect(post).to respond_to :comments=
    end

    it "should return an empty array from comments for an object with none" do
      expect(empty_post.comments).to eql []
    end

    it "should return an array of comments for an object with some" do
      expect(post.comments.size).to eql 2
      post.comments.each do |comment|
        expect(comment).to be_a Comment
      end
    end

    it "should allow setting and saving non-array elements" do
      post.title = "test post title"
      post.save!
      expect(post.title).to eql 'test post title'
    end

    it "should allow setting array elements" do
      post.comments = (post.comments + [empty_comment])
      expect(post.comments.size).to eql 3
      expect(post.comments).to include empty_comment
    end

    it "should allow saving array elements" do
      comments = post.comments + [empty_comment]
      post.comments = (post.comments + [empty_comment])
      expect(post.comments.size).to eql 3
      post.save!
      expect(post.comments.size).to eql 3
      post.comments.each do |comment|
        expect(comments).to include comment
      end
    end

    context "given all associations have a base_uri" do
      before do
        Post.class_eval {
          configure :base_uri => "http://example.org/posts"
        }

        Comment.class_eval {
          configure :base_uri => "http://example.org/comments"
        }
      end

      it "should assign comments by their IDs" do
        cids = post.comment_ids.first
        post.comment_ids = [cids, ""]

        expect(post.comment_ids).to eql [cids]
      end
    end
  end
end
