# Spira

It's time to breathe life into your linked data.

---

## Synopsis
Spira is a framework for using the information in RDF.rb repositories as model
objects.  It gives you the ability to work in a resource-oriented way without
losing access to statement-oriented nature of linked data, if you so choose.
It can be used either to access existing RDF data in a resource-oriented way,
or to create a new store of RDF data based on simple defaults.

### Example

    class Person
    
      include Spira::Resource

      default_base_uri "http://example.org/example/people"
    
      property :name, RDF::FOAF.name, String
      property :age,  RDF::FOAF.age,  Integer

    end

    bob = Person.create 'bob'
    bob.age  = 15
    bob.name = "Bob Smith"
    bob.save!

    bob.each_statement
    #<http://example.org/example/people/bob> <http://xmlns.com/foaf/0.1/age> "15"^^<http://www.w3.org/2001/XMLSchema#integer> .
    #<http://example.org/example/people/bob> <http://www.w3.org/2000/01/rdf-schema#label> "Bob Smith" .
   
### Features

 * Extensible validations system
 * Easy to use multiple data sources
 * Easy to adapt models to existing data
 * Objects are still RDF.rb-compatible enumerable objects
 * No need to put everything about an object into Spira
 * Easy to use a resource as multiple models

## Getting Started

By far the easiest way to work with Spira is to install it via Rubygems:

    $ sudo gem install spira

Nonetheless, downloads are available at the Github project page.

## Defining Model Classes

To use Spira, define model classes for your RDF data.  Spira classes include
RDF, and thus have access to all `RDF::Vocabulary` classes and `RDF::URI`
without the `RDF::` prefix.  For example:

    require 'spira'
    
    class CD
      include Spira::Resource
      default_base_uri 'http://example.org/cds'
      property :name,   :predicate => DC.title,   :type => XSD.string
      property :artist, :predicate => URI.new('http://example.org/vocab/artist'), :type => :artist
    end
    
    class Artist
      include Spira::Resource
      default_base_uri 'http://example.org/artists'
      property :name, :predicate => DC.title, :type => XSD.string
      has_many :cds,  :predicate => URI.new('http://example.org/vocab/published_cd'), :type => XSD.string
    end

Then use your model classes, in a way more or less similar to any number of ORMs:

    cd = CD.create "queens-greatest-hits"
    cd.name = "Queen's greatest hits"
    artist = Artist.create "queen"
    artist.name = "Queen"
    
    cd.artist = artist
    cd.save!
    artist.cds = [cd]
    artist.save!

    queen = Arist.find 'queen'
    hits = CD.find 'queens-greatest-hits'
    hits.artist == artist == queen

### Absolute and Relative URIs

A class with a base URI can reference objects by a short name:

    Artist.find 'queen'

However, a class is not required to have a base URI, and even if it does, it
can always access classes with a full URI:

    nk = Artist.find RDF::URI.new('http://example.org/my-hidden-cds/new-kids')
    
### Class Options

A number of options are available for Spira classes.

#### default_base_uri

A class with a `default_base_uri` set (either an `RDF::URI` or a `String`) will
use that URI as a base URI for non-absolute `create` and `find` calls.

Example
    CD.find 'queens-greatest-hits' # is the same as...
    CD.find RDF::URI.new('http://example.org/cds/queens-greatest-hits')

#### type

A class with a `type` set is assigned an `RDF.type` on creation and saving.

    class Album
      include Spira::Resource
      type RDF::URI.new('http://example.org/types/album')
      property :name,   :predicate => DC.title
    end

    rolling_stones = Album.create RDF::URI.new('http://example.org/cds/rolling-stones-hits')
    # See RDF.rb for more information about #has_predicate?
    rolling_stones.has_predicate?(RDF.type) #=> true
    Album.type #=> RDF::URI('http://example.org/types/album')

In addition, one can count the members of a class with a `type` defined:

    Album.count  #=> 1 

#### property

A class declares property members with the `property` function.  See `Property Options` for more information.

#### has_many

A class declares list members with the `has_many` function.  See `Property Options` for more information.

#### default_vocabulary

A class with a `default_vocabulary` set will transparently create predicates for defined properties:

    class Song
      include Spira::Resource
      default_vocabulary RDF::URI.new('http://example.org/vocab')
      default_base_uri 'http://example.org/songs'
      property :title
      property :author, :type => :artist
    end

    dancing_queen = Song.create 'dancing-queen'
    dancing_queen.title = "Dancing Queen"
    dancing_queen.artist = abba
    dancing_queen.has_predicate?(RDF::URI.new('http://example.org/vocab/title'))  #=> true
    dancing_queen.has_predicate?(RDF::URI.new('http://example.org/vocab/artist')) #=> true

#### default_source

Provides this class with a default repository to use instead of the `:default`
repository if one is not set.

    class Song
      default_source :songs
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
   RDF::XSD entry, or another Spira model class, referenced as a symbol. Default: `String`
 * `:predicate`: The predicate to use for this type.  This can be any RDF URI.
   This option is required unless the `default_vocabulary` has been used.

### Relations

If the `:type` of a spira class is the name of another Spira class as a symbol,
such as `:artist` for `Artist`, Spira will attempt to load the referenced
object when the appropriate property is accessed.

In the RDF store, this will be represented by the URI of the referenced object.

## Defining Repositories

You can define multiple repositories with Spira, and use more than one at a time:

    require 'rdf/ntriples'
    require 'rdf/sesame'
    Spira.add_repository! :cds,    RDF::Sesame::Repository.new 'some_server'
    Spira.add_repository! :albums, RDF::Repository.load('some_file.nt')

    CD.repository = :cds
    Album.repository = :albums

Objects can reference each other cross-repository.

If no repository has been specified, the `:default` repository will be used.

    repo = RDF::Repository.new
    Spira.add_repository! :default, repo
    Artist.repository == repo #=> true

Classes can specify a default repository to use other than `:default` with the
`default_source` function:

    class Song
      default_source :songs
    end

    Song.repository #=> nil, won't use :default

## Validations

Before saving, each object will run a `validate` function, if one exists.  You
can use the built in `assert` and assert helpers such as `assert_set` and
`asssert_numeric`.


    class CD
      def validate
        # the only valid CDs are ABBA CD's!
        assert(artist.name == "Abba","Could not save a CD made by #{artist.name}")
      end
    end

    dancing-queen.artist = nil
    dancing-queen.save!  #=> ValidationError

    dancing-queen.artist = abba
    dancing-queen.save!  #=> true

## Using Model Objects as RDF.rb Objects

All model objects are fully-functional as `RDF::Enumerable`, `RDF::Queryable`,
and `RDF::Mutable`.  This lets you manipulate objects on the RDF statement
level.  You can also access attributes that are not defined as properties.

## Support

There are a number of ways to ask for help.  In declining order of likelihood of response:

 * Fork the project and write a failing test, or a pending test for a feature request
 * You can post issues to the Github issue queue
 * (there might one day be a google group or other such support channel, but not yet)

## Authors, Development, and License

#### Authors
 * Ben Lavender <blavender@gmail.com>

#### 'License'
Spira is free and unemcumbered software released into the public
domain.  For more information, see the included UNLICENSE file.

#### Contributing
Fork it on Github and go.  Please make sure you're kosher with the UNLICENSE
file before contributing.










