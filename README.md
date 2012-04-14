# FOREWORD

This is a branch of Spira that makes use of ActiveModel. The goal of this branch is
to replace all the internals of Spira with ActiveModel hooks, and thus get rid of
superfluous code and increase compatibility with Rails stack.

Although I've been trying to make the impact of this transition to be as little
as possible, there are a few changes that you should be aware of:

 * Customary record manipulation methods are preferred now.
   This means, you should use more habitual "save", "destroy", "update_attributes", etc.
   instead of the "save!", "destroy!", "update", "update!" and others, as introduced
   by the original Spira gem.
 * Callbacks are now handled by ActiveModel. Previous ways of defining them are
   no longer valid. This also introduces the "before_", "after_" and "around_" callbacks
   as well as their "_validation", "_save", "_update" and "_create" companions for you to enjoy.
 * Validations are also handled by ActiveModel. With all the helper methods you had in
   ActiveRecord.
 * A spira resource (class) must be defined by *inheriting* it from Spira::Base.
   Do not use "include Spira::Resource" as a way to define your Spira resource -
   it is broken and will be gone soon.
 * Take note about the difference of "new_record?" and "exists?" methods.
   Read the comments on those. And "#exists?" (instance method) is going away soon, too.
 * "after/before_create" callbacks are *not* called when only the properties of your
   Spira resource are getting persisted. You may create a "type"-less Spira resource,
   assign properties to it, then #save it -- "_create" callbacks will not be triggered,
   because Spira cannot infer a resource definition ("resource - RDF.type - type")
   for such resource and will only persist its properties.
   Although this is how the original Spira behaves too, I thought I'd state it
   explicitly here for when you start freaking out.
 * Configuration options "base_uri", "default_vocabulary" and "repository_name" are
   now configured via "configure" method (see the examples below).

---

# Spira

It's time to breathe life into your linked data.

---

## Synopsis
Spira is a framework for using the information in [RDF.rb][] repositories as model
objects.  It gives you the ability to work in a resource-oriented way without
losing access to statement-oriented nature of linked data, if you so choose.
It can be used either to access existing RDF data in a resource-oriented way,
or to create a new store of RDF data based on simple defaults.

An introductory blog post is at <http://blog.datagraph.org/2010/05/spira>

A changelog is available in the {file:CHANGES.md} file.

### Example

    class Person < Spira::Base

      configure :base_uri => "http://example.org/example/people"
    
      property :name, :predicate => FOAF.name, :type => String
      property :age,  :predicate => FOAF.age,  :type => Integer

    end

    bob = RDF::URI("http://example.org/people/bob").as(Person)
    bob.age  = 15
    bob.name = "Bob Smith"
    bob.save!

    bob.each_statement {|s| puts s}
    #=> RDF::Statement:0x80abb80c(<http://example.org/example/people/bob> <http://xmlns.com/foaf/0.1/name> "Bob Smith" .)
    #=> RDF::Statement:0x80abb8fc(<http://example.org/example/people/bob> <http://xmlns.com/foaf/0.1/age> "15"^^<http://www.w3.org/2001/XMLSchema#integer> .)
   
### Features

 * Extensible validations system
 * Extensible types system
 * Easy to use multiple data sources
 * Easy to adapt models to existing data
 * Open-world semantics
 * Objects are still RDF.rb-compatible enumerable objects
 * No need to put everything about an object into Spira
 * Easy to use a resource as multiple models

## Getting Started

The easiest way to work with Spira is to install it via Rubygems:

    $ sudo gem install spira

Downloads will be available on the github project page, as well as on Rubyforge.

## Defining Model Classes

To use Spira, define model classes for your RDF data.  Spira classes include
RDF, and thus have access to all `RDF::Vocabulary` classes and `RDF::URI`
without the `RDF::` prefix.  For example:

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

Then use your model classes, in a way more or less similar to any number of ORMs:

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

### URIs and Blank Nodes

Spira instances have a subject, which is either a URI or a blank node.

A class with a base URI can instantiate with a string (or anything, via to_s),
and it will have a URI representation:

    Artist.for('queen')

However, a class is not required to have a base URI, and even if it does, it
can always access classes with a full URI:

    nk = Artist.for(RDF::URI.new('http://example.org/my-hidden-cds/new-kids'))

If you have a URI that you would like to look at as a Spira resource, you can instantiate it from the URI:

    RDF::URI.new('http://example.org/my-hidden-cds/new-kids').as(Artist)
    # => <Artist @subject=http://example.org/my-hidden-cds/new-kids>

Any call to 'for' with a valid identifier will always return an object with nil
fields.  It's a way of looking at a given resource, not a closed-world mapping
to one.

You can also use blank nodes more or less as you would a URI:

    remix_artist = Artist.for(RDF::Node.new)
    # => <Artist @subject=#<RDF::Node:0xd1d314(_:g13751060)>>
    RDF::Node.new.as(Artist)
    # => <Artist @subject=#<RDF::Node:0xd1d314(_:g13751040)>>

Finally, you can create an instance of a Spira projection with #new, and you'll
get an instance with a shiny new blank node subject:

    formerly_known_as_prince = Artist.new
    # => <Artist @subject=#<RDF::Node:0xd1d314(_:g13747140)>>

### Class Options

A number of options are available for Spira classes.

#### base_uri

A class with a `base_uri` set (either an `RDF::URI` or a `String`) will
use that URI as a base URI for non-absolute `for` calls.

Example
    CD.for 'queens-greatest-hits' # is the same as...
    CD.for RDF::URI.new('http://example.org/cds/queens-greatest-hits')

#### type

A class with a `type` set is assigned an `RDF.type` on creation and saving.

    class Album < Spira::Base
      type URI.new('http://example.org/types/album')
      property :name,   :predicate => DC.title
    end

    rolling_stones = Album.for RDF::URI.new('http://example.org/cds/rolling-stones-hits')
    # See RDF.rb at http://rdf.rubyforge.org/RDF/Enumerable.html for more information about #has_predicate?
    rolling_stones.has_predicate?(RDF.type) #=> true
    Album.type #=> RDF::URI('http://example.org/types/album')

In addition, one can count the members of a class with a `type` defined:

    Album.count  #=> 1 


It is possible to assign multiple types to a Spira class:

    class Man < Spira::Base
      type RDF::URI.new('http://example.org/people/father')
      type RDF::URI.new('http://example.org/people/cop')
    end

All assigned types are accessible via "types":

    Man.types #=> #<Set: {#<RDF::URI:0xd5ebc0(http://example.org/people/father)>, #<RDF::URI:0xd5e4b8(http://example.org/people/cop)>}>

Also note that "type" actually returns a first type from the list of types.


#### property

A class declares property members with the `property` function.  See `Property Options` for more information.

#### has_many

A class declares list members with the `has_many` function.  See `Property Options` for more information.

#### default_vocabulary

A class with a `default_vocabulary` set will transparently create predicates for defined properties:

    class Song < Spira::Base
      configure :default_vocabulary => URI.new('http://example.org/vocab'),
                :base_uri => 'http://example.org/songs'
      property :title
      property :author, :type => :artist
    end

    dancing_queen = Song.for 'dancing-queen'
    dancing_queen.title = "Dancing Queen"
    dancing_queen.artist = abba
    # See RDF::Enumerable for #has_predicate?
    dancing_queen.has_predicate?(RDF::URI.new('http://example.org/vocab/title'))  #=> true
    dancing_queen.has_predicate?(RDF::URI.new('http://example.org/vocab/artist')) #=> true

#### repository_name

Provides this class with a default repository to use instead of the `:default`
repository if one is not set.

    class Song < Spira::Base
      configure :repository_name => :songs
    end

See 'Defining Repositories' for more information.

### Property Options

Spira classes can have properties that are either singular or a list.  For a
list, define the property with `has_many`, for a property with a single item,
use `property`.  The semantics are otherwise the same.  A `has_many` property
will always return a list, including an empty list for no value.  All options
for `property` work for `has_many`.

    property :artist, :type => :artist    #=> cd.artist returns a single value
    has_many :cds,    :type => :cd        #=> artist.cds returns an array

Property always takes a symbol name as a name, and a variable list of options.  The supported options are:

 * `:type`: The type for this property.  This can be a Ruby base class, an 
   RDF::XSD entry, or another Spira model class, referenced as a symbol.  See
   **Types** below.  Default: `Any`
 * `:predicate`: The predicate to use for this type.  This can be any RDF URI.
   This option is required unless the `default_vocabulary` has been used.

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

    module Spira::Types
      class Integer
    
        include Spira::Type
    
        def self.unserialize(value)
          value.object
        end
    
        def self.serialize(value)
          RDF::Literal.new(value)
        end
    
        register_alias XSD.integer
      end
    end

Classes can now use this particular type like so:

    class Test < Spira::Base
      property :test1, :type => Integer
      property :test2, :type => XSD.integer
    end

Spira classes include the Spira::Types namespace, where several default types
are implemented:

  * `Integer`
  * `Float`
  * `Boolean`
  * `String`
  * `Any`

The default type for a Spira property is `Spira::Types::Any`, which uses
`RDF::Literal`'s automatic boxing/unboxing of XSD types as best it can.  See
`[RDF::Literal](http://rdf.rubyforge.org/RDF/Literal.html)` for more information.

You can implement your own types as well.  Your class' serialize method should
turn an RDF::Value into a ruby object, and vice versa.

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

## Defining Repositories

You can define multiple repositories with Spira, and use more than one at a time:

    require 'rdf/ntriples'
    require 'rdf/sesame'
    Spira.add_repository! :cds,    RDF::Sesame::Repository.new 'some_server'
    Spira.add_repository! :albums, RDF::Repository.load('some_file.nt')

    class CD < Spira::Base
      configure :repository_name => :cds
    end
    class Album < Spira::Base
      configure :repository_name => :albums
    end

Objects can reference each other cross-repository.

If no repository has been specified, the `:default` repository will be used.

    repo = RDF::Repository.new
    Spira.add_repository! :default, repo
    Artist.repository == repo #=> true

Classes can specify a default repository to use other than `:default` with the
`repository_name` function:

    class Song < Spira::Base
      configure :repository_name => :songs
    end

    Song.repository #=> nil, won't use :default

## Validations

[removed]
See the description of ActiveModel::Validations.

## Hooks

[removed]
See the description of ActiveModel::Callbacks.

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

## Authors, Development, and License

#### Authors
 * Ben Lavender <blavender@gmail.com>
 * Slava Kravchenko <slava.kravchenko@gmail.com>

#### 'License'
Spira is free and unemcumbered software released into the public
domain.  For more information, see the included UNLICENSE file.

#### Contributing
Fork it on Github and go.  Please make sure you're kosher with the UNLICENSE
file before contributing.

[public-rdf-ruby w3c mailing list]:         http://lists.w3.org/Archives/Public/public-rdf-ruby/
[RDF.rb]:                                   http://rdf.rubyforge.org
