# Spira [![Build Status](https://travis-ci.org/ruby-rdf/spira.png?branch=develop)](http://travis-ci.org/ruby-rdf/spira) [![Coverage Status](https://coveralls.io/repos/ruby-rdf/spira/badge.png?branch=develop)](https://coveralls.io/r/ruby-rdf/spira) [![Code Climate](https://codeclimate.com/github/ruby-rdf/spira.png)](https://codeclimate.com/github/ruby-rdf/spira) [![Dependency Status](https://gemnasium.com/ruby-rdf/spira.png)](https://gemnasium.com/ruby-rdf/spira)

It's time to breathe life into your linked data.

## Need Help? Use our Google Group

If you have any question on how to use Spira, please use the [Google Group ruby-rdf](https://groups.google.com/forum/#!forum/ruby-rdf).

## Synopsis
Spira is a framework for using the information in [RDF.rb][] repositories as model
objects.  It gives you the ability to work in a resource-oriented way without
losing access to statement-oriented nature of linked data, if you so choose.
It can be used either to access existing RDF data in a resource-oriented way,
or to create a new store of RDF data based on simple defaults.

An introductory blog post is at <http://blog.datagraph.org/2010/05/spira>

A changelog is available in the {file:CHANGES.md} file.

### Example

```ruby
class Person < Spira::Base

  configure :base_uri => "http://example.org/example/people"

  property :name, :predicate => FOAF.name, :type => String
  property :age,  :predicate => FOAF.age,  :type => Integer

end

Spira.repository = RDF::Repository.new

bob = RDF::URI("http://example.org/people/bob").as(Person)
bob.age  = 15
bob.name = "Bob Smith"
bob.save!

bob.each_statement {|s| puts s}
#=> RDF::Statement:0x80abb80c(<http://example.org/example/people/bob> <http://xmlns.com/foaf/0.1/name> "Bob Smith" .)
#=> RDF::Statement:0x80abb8fc(<http://example.org/example/people/bob> <http://xmlns.com/foaf/0.1/age> "15"^^<http://www.w3.org/2001/XMLSchema#integer> .)
```

### Features

 * Extensible validations system
 * Extensible types system
 * Easy to adapt models to existing data
 * Open-world semantics
 * Objects are still RDF.rb-compatible enumerable objects
 * No need to put everything about an object into Spira
 * Easy to use a resource as multiple models

## ActiveModel integration

This is a version of Spira that makes use of ActiveModel. The goal of this version is
to replace all the internals of Spira with ActiveModel hooks, and thus get rid of
superfluous code and increase compatibility with Rails stack. I want it to be
a drop-in replacement for ActiveRecord or any other mature ORM solution they use
with Ruby on Rails.

Although I've been trying to make the impact of this transition to be as little
as possible, there are a few changes that you should be aware of:

 * Read the comments on "new_record?" and "reload" methods. They are key methods in
   understanding how Spira is working with the repository. Basically, a Spira record
   is new, if the repository has no statements with this record as subject. This means,
   that *the repository is queried every time you invoke "new_record?"*.
   Also note that if Spira.repository is not set, your Spira resource will always be "new".
   Also note that instantiating a new Spira resource sends a query to the repository,
   if it is set, but should work just fine even if it's not (until you try to "save" it).
 * Customary Rails' record manipulation methods are preferred now.
   This means, you should use more habitual "save", "destroy", "update_attributes", etc.
   instead of the "save!", "destroy!", "update", "update!" and others, as introduced
   by the original Spira gem.
 * Callbacks are now handled by ActiveModel. Previous ways of defining them are
   no longer valid. This also introduces the "before_", "after_" and "around_" callbacks
   as well as their "_validation", "_save", "_update" and "_create" companions for you to enjoy.
 * Validations are also handled by ActiveModel. With all the helper methods you have in
   ActiveRecord.
 * A spira resource (class) must be defined by *inheriting* it from Spira::Base.
   Using "include Spira::Resource" is *temporarily* broken, but will be back at some point,
   with improvements and stuff.
 * "after/before_create" callbacks are *not* called when only the properties of your
   Spira resource are getting persisted. That is, you may create a "type"-less Spira resource,
   assign properties to it, then #save it -- "_create" callbacks will not be triggered,
   because Spira cannot infer a resource definition ("resource - RDF.type - type")
   for such resource and will only persist its properties.
   Although this is how the original Spira behaves too, I thought I'd state it
   explicitly here before you start freaking out.
 * Configuration options "base_uri", "default_vocabulary" are
   now configured via "configure" method (see the examples below).
 * A couple of (not so) subtle changes:
   1) Global caching is gone. This means that "artist.works.first.artist" (reverse lookup)
   does not return the original artist, but its copy retrieved from the database.

## Getting Started

The easiest way to work with Spira is to install it via Rubygems:

    $ sudo gem install spira

Downloads will be available on the github project page, as well as on Rubyforge.

## Defining Model Classes

To use Spira, define model classes for your RDF data.  Spira classes include
RDF, and thus have access to all `RDF::Vocabulary` classes and `RDF::URI`
without the `RDF::` prefix.  For example:

```ruby
require 'spira'
    
class CD < Spira::Base
  configure :base_uri => 'http://example.org/cds'
  property :name,   :predicate => DC.title,   :type => XSD.string
  property :artist, :predicate => URI.new('http://example.org/vocab/artist'), :type => :artist
end

class Artist < Spira::Base
  configure :base_uri => 'http://example.org/artists'
  property :name, :predicate => DC.title, :type => XSD.string
  has_many :cds,  :predicate => URI.new('http://example.org/vocab/published_cd'), :type => XSD.string
end
```

Then define a Spira repository (see [Defining Repositories](#defining-repositories)) to use your model classes, in a way more or less similar to any number of ORMs:

```ruby
Spira.repository = RDF::Repository.new

cd = CD.for("queens-greatest-hits")
cd.name = "Queen's greatest hits"
artist = Artist.for("queen")
artist.name = "Queen"

cd.artist = artist
cd.save!
artist.cds = [cd]
artist.save!

queen = Artist.for('queen')
hits = CD.for 'queens-greatest-hits'
hits.artist == artist == queen
```

### URIs and Blank Nodes

Spira instances have a subject, which is either a URI or a blank node.

A class with a base URI can instantiate with a string (or anything, via to_s),
and it will have a URI representation:

```ruby
Artist.for('queen')
```

However, a class is not required to have a base URI, and even if it does, it
can always access classes with a full URI:

```ruby
nk = Artist.for(RDF::URI.new('http://example.org/my-hidden-cds/new-kids'))
```

If you have a URI that you would like to look at as a Spira resource, you can instantiate it from the URI:

```ruby
RDF::URI.new('http://example.org/my-hidden-cds/new-kids').as(Artist)
# => <Artist @subject=http://example.org/my-hidden-cds/new-kids>
```

Any call to 'for' with a valid identifier will always return an object with nil
fields.  It's a way of looking at a given resource, not a closed-world mapping
to one.

You can also use blank nodes more or less as you would a URI:

```ruby
remix_artist = Artist.for(RDF::Node.new)
# => <Artist @subject=#<RDF::Node:0xd1d314(_:g13751060)>>
RDF::Node.new.as(Artist)
# => <Artist @subject=#<RDF::Node:0xd1d314(_:g13751040)>>
```

Finally, you can create an instance of a Spira projection with #new, and you'll
get an instance with a shiny new blank node subject:

```ruby
formerly_known_as_prince = Artist.new
# => <Artist @subject=#<RDF::Node:0xd1d314(_:g13747140)>>
```

### Class Options

A number of options are available for Spira classes.

#### base_uri

A class with a `base_uri` set (either an `RDF::URI` or a `String`) will
use that URI as a base URI for non-absolute `for` calls.

Example
```ruby
CD.for 'queens-greatest-hits' # is the same as...
CD.for RDF::URI.new('http://example.org/cds/queens-greatest-hits')
```

#### type

A class with a `type` set is assigned an `RDF.type` on creation and saving.

```ruby
class Album < Spira::Base
  type URI.new('http://example.org/types/album')
  property :name,   :predicate => DC.title
end

Spira.repository = RDF::Repository.new

rolling_stones = Album.for RDF::URI.new('http://example.org/cds/rolling-stones-hits')
# See RDF.rb at http://rdf.rubyforge.org/RDF/Enumerable.html for more information about #has_predicate?
rolling_stones.has_predicate?(RDF.type) #=> true
Album.type #=> RDF::URI('http://example.org/types/album')
```

In addition, one can count the members of a class with a `type` defined:

```ruby
Album.count  #=> 1 
```


It is possible to assign multiple types to a Spira class:

```ruby
class Man < Spira::Base
  type RDF::URI.new('http://example.org/people/father')
  type RDF::URI.new('http://example.org/people/cop')
end
```

All assigned types are accessible via "types":

```ruby
Man.types
# => #<Set: {#<RDF::URI:0xd5ebc0(http://example.org/people/father)>, #<RDF::URI:0xd5e4b8(http://example.org/people/cop)>}>
```

Also note that "type" actually returns a first type from the list of types.


#### property

A class declares property members with the `property` function.  See `Property Options` for more information.

#### has_many

A class declares list members with the `has_many` function.  See `Property Options` for more information.

#### default_vocabulary

A class with a `default_vocabulary` set will transparently create predicates for defined properties:

```ruby
class Song < Spira::Base
  configure :default_vocabulary => URI.new('http://example.org/vocab'),
            :base_uri => 'http://example.org/songs'
  property :title
  property :author, :type => :artist
end

Spira.repository = RDF::Repository.new

dancing_queen = Song.for 'dancing-queen'
dancing_queen.title = "Dancing Queen"
dancing_queen.artist = abba
# See RDF::Enumerable for #has_predicate?
dancing_queen.has_predicate?(RDF::URI.new('http://example.org/vocab/title'))  #=> true
dancing_queen.has_predicate?(RDF::URI.new('http://example.org/vocab/artist')) #=> true
```

### Property Options

Spira classes can have properties that are either singular or a list.  For a
list, define the property with `has_many`, for a property with a single item,
use `property`.  The semantics are otherwise the same.  A `has_many` property
will always return a list, including an empty list for no value.  All options
for `property` work for `has_many`.

```ruby
property :artist, :type => :artist    #=> cd.artist returns a single value
has_many :cds,    :type => :cd        #=> artist.cds returns an array
```

Property always takes a symbol name as a name, and a variable list of options.  The supported options are:

 * `:type`: The type for this property.  This can be a Ruby base class, an 
   RDF::XSD entry, or another Spira model class, referenced as a symbol.  See
   **Types** below.  Default: `Any`
 * `:predicate`: The predicate to use for this type.  This can be any RDF URI.
   This option is required unless the `default_vocabulary` has been used.
 * `:localized`: Indicates if the property is multilingual. See 'Localized Properties'

#### Localized Properties

A localized property allows to define a value per language. It only works with
properties having a single item, ie defined with `property`.

```ruby
class Article < Spira::Base
  property :label, :localized => true
end

Spira.repository = RDF::Repository.new

# default locale :en
random_article = Article.for 'random-article'
random_article.label = "A label in english"
i18n.locale = :fr
random_article.label = "Un libellé en français"

random_article.label_native
# #=> [#<RDF::Literal:0xdb47c8("A label in english"@en)>, #<RDF::Literal:0xe5c3d8("Un libellé en français"@fr)>]

random_article.label_with_locales
# #=> {:en=>"A label in english", :fr=>"Un libellé en français"}
```

### Types

A property's type can be either a class which includes Spira::Type or a
reference to another Spira model class, given as a symbol.

#### Relations

If the `:type` of a spira class is the name of another Spira class as a symbol,
such as `:artist` for `Artist`, Spira will attempt to load the referenced
object when the appropriate property is accessed.

In the RDF store, this will be represented by the URI of the referenced object.

#### Type Classes

A type class includes Spira::Type, and can implement serialization and
deserialization functions, and register aliases to themselves if their datatype
is usually expressed as a URI.  Here is the built-in Spira Integer class:

```ruby
module Spira::Types
  class Integer

    include Spira::Type

    def self.unserialize(value)
      value.object
    end

    def self.serialize(value)
      RDF::Literal.new(value)
    end

    register_alias RDF::XSD.integer
  end
end
```

Classes can now use this particular type like so:

```ruby
class Test < Spira::Base
  property :test1, :type => Integer
  property :test2, :type => RDF::XSD.integer
end
```

Spira classes include the Spira::Types namespace, where several default types
are implemented:

  * `Integer`
  * `Float`
  * `Boolean`
  * `String`
  * `Any`

The default type for a Spira property is `Spira::Types::Any`, which uses
`RDF::Literal`'s automatic boxing/unboxing of XSD types as best it can.
See [`RDF::Literal`](http://rdf.rubyforge.org/RDF/Literal.html) for more information.

You can implement your own types as well.  Your class' serialize method should
turn an RDF::Value into a ruby object, and vice versa.

```ruby
module MyModule
  class MyType
    include Spira::Type
    def self.serialize(value)
      ...
    end

    def self.unserialize(value)
      ...
    end
  end
end

class MyClass < Spira::Base
  property :property1, :type => MyModule::MyType
end
```

## Defining Repositories

You can work on any kind of RDF::Repository with Spira:

```ruby
require 'rdf/ntriples'
require 'rdf/sesame'

class Album < Spira::Base
end

Spira.repository = RDF::Sesame::Repository.new 'some_server'
...

Spira.repository = RDF::Repository.load('some_file.nt')
...

Spira.using_repository(RDF::Repository.load('some_file.nt')) do
   ...
end
```

Spira.repository is thread-safe, which means that each thread stores its own instance.
It allows you to work on multiple repositories at the same time:

```ruby
threads = []
repositories = [RDF::Repository.new, RDF::Repository.new, RDF::Repository.new]

repositories.each do |repository|
  threads << Thread.new(repository) do |repository|
    Spira.repository = repository

    album = Album.for("http://theperson.com/album/random_name")
    album.year = 1950 + (rand*100).to_i
    album.save!
  end
end

threads.map(&:join)
repositories.map(&:size).join(', ') # 1, 1, 1
```

## Validations

[removed]
See the description of `ActiveModel::Validations`.

## Hooks

[removed]
See the description of `ActiveModel::Callbacks`.

## Using Model Objects as RDF.rb Objects

All model objects are fully-functional as `RDF::Enumerable`, `RDF::Queryable`,
and `RDF::Mutable`.  This lets you manipulate objects on the RDF statement
level.  You can also access attributes that are not defined as properties.

## Support

There are a number of ways to ask for help.  In declining order of preference:

 * Fork the project and write a failing test, or a pending test for a feature request
 * Ask on the [public-rdf-ruby w3c mailing list][]
 * You can post issues to the Github issue queue
 * (there might one day be a google group or other such support channel, but not yet)

## 'License'
Spira is free and unemcumbered software released into the public
domain.  For more information, see the included UNLICENSE file.

## Contributing
This repository uses [Git Flow](https://github.com/nvie/gitflow) to mange development and release activity. All submissions _must_ be on a feature branch based on the _develop_ branch to ease staging and integration.

* Do your best to adhere to the existing coding conventions and idioms.
* Don't use hard tabs, and don't leave trailing whitespace on any line.
* Do document every method you add using [YARD][] annotations. Read the
  [tutorial][YARD-GS] or just look at the existing code for examples.
* Don't touch the `.gemspec`, `VERSION` or `AUTHORS` files. If you need to
  change them, do so on your private branch only.
* Do feel free to add yourself to the `CREDITS` file and the corresponding
  list in the the `README`. Alphabetical order applies.
* Do note that in order for us to merge any non-trivial changes (as a rule
  of thumb, additions larger than about 15 lines of code), we need an
  explicit [public domain dedication][PDD] on record from you.

[public-rdf-ruby w3c mailing list]:         http://lists.w3.org/Archives/Public/public-rdf-ruby/
[RDF.rb]:          http://rubygems.org/gems/rdf
