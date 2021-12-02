# Changelog for Spira <https://github.com/rdf-ruby/spira>
  
## [Unreleased]
### Changed

* Spira#using_repository now returns the given repository

## 0.3.0
 * General updates to bring up to date.

## 0.0.12
 * Implemented #validate, #validate! (refactored from #save!)
 * Force to_a on query results when constructing to force the promise-like
   semantics of SPARQL::Client

## 0.0.11
 * Bumped the version dependency on rdf-isomorphic to 0.3.0
 * Added support for before_create, after_create, before_save, after_save,
   after_update, before_destroy and after_destroy hooks.
 * Switch RDF.rb dependency to >= instead of ~>

## 0.0.10
 * Use RDF::URI.intern on URIs generated via base URIs
 * Added a Spira::Types::Native, which will return the RDF::Value for a given
   predicate directly without any serialization or dserialization.

## 0.0.9
 * Fix a bug with Spira::Types::Any that prevented blank node objects
 * Added Spira::Resource#copy, #copy!, #copy_resource!, and #rename!
 * Fix a bug with fragment RDF::URI arguments that prevented correct URI
   construction
 * Added Spira::Resource.project(subject, attributes, &block), which creates a
   new instance without attempting to perform any base_uri logic on the given
   subject. This provides a supported API entry point for implementors to
   create their own domain-specific URI construction.
 * Updating a value to nil will now remove it from the repository on #save!
 * Tweaks to dirty tracking to correctly catch both changed and updated values.
   All tests pass for the first time with this change.
 * Change gemspec name to work with bundler

## 0.0.8
 * Remove type checking for repository addition.  More power in return for 
   slightly more difficult error messages.
 * Repositories added via klass, \*arg are now only instantiated on first use
   instead of immediately.
 * RDF::URI#as, RDF::Node#as, Resource.for, and Resource#new can now all accept
   a block, which yields the new instance and saves it after the block.
 * Clarify error message when default repository is not setup
 * Added a weak-reference identity map for each instance.  Any circular references in
   relations will now return the original object instead of querying for a new 
   one.
 * Use a weak-reference identity map when iterating by class.
 * When serializing/unserializing, duck typing (:serialize, :unserialize) is now
   permitted.

## 0.0.7
 * Added Resource.\[\], an alias for Resource.for
 * Resource.each now correctly raises an exception when a repository isn't found

## 0.0.6
 * Added #exists?, which returns a boolean if an instance exists in
   the backing store.
 * Added #data, which returns an enumerator of all RDF data for a subject, not
   just model data.
 * #save! and #update! now return self for chaining
 * Implemented #update and #update!, which allow setting multiple properties 
   at once
 * Existing values not matching a model's defined type will now be deleted on 
   #save!
 * Saving resources will now only update dirty fields
 * Saving resources now removes all existing triples for a given predicate 
   if the field was updated instead of only removing one.
 * Implemented and documented #destroy!, #destroy!(:subject), 
   #destroy!(:object), and #destroy!(:completely).  Removed #destroy_resource!
 * has_many collections are now Sets and not Arrays, more accurately reflecting
   RDF semantics.
 * The Any (default) property type will now work fine with URIs
 * Added ResourceDeclarationError to replace various errors that occur during
   invalid class declarations via the DSL.
 * Raise an error if a non-URI predicate is given in the DSL
 * Small updates for RDF.rb 0.2.0
 * Implemented dirty field tracking.  Resource#dirty?(:name) will now report if
   a field has not been saved.

## 0.0.5
 * Relations can now find related classes in modules, either by absolute
   reference, or by class name if they are in the same namespace.  
 * Fix a bug with default_vocabulary in which a '/' was appended to
   vocabularies ending in '#' 
 * Fix a bug with the Decimal type where round-tripping was incorrect
 * Fix some error messages that were missing closing parentheses

## 0.0.4
 * Added a Decimal type
 * Small updates for RDF.rb 0.2.0 compatibility
 * Add a Spira::Base class that can be inherited from for users who prefer to
   inherit rather than include.
 * Resource#new returns to the public API as a way to create a resource with a
   new blank node subject.

## 0.0.3
 * Bumped promise dependency to 0.1.1 to fix a Ruby 1.9 warning
 * Rework error handling when a repository is not configured; this should
   always now raise a Spira::NoRepositoryError regardless of what operation 
   was attempted, and the error message was improved as well.
 * A '/' is no longer appended to base URIs ending with a '#'
 * Resources can now take a BNode as a subject.  Implemented #node?, #uri,
   #to_uri, #to_node, and #to_subject in support of this; see the yardocs for
   exact semantics.  RDF::Node is monkey patched with #as, just like RDF::URI,
   for instantiation.   Old code should not break, but if you want to add
   BNodes, you may be using #uri where you want to now be using #subject.

## 0.0.2
 * Implemented #each on resource classes, allowing classes with a defined RDF
   type to be enumerated
 * Fragment URIs are now used as strings, allowing i.e. Integers to be used as
   the final portion of a URI for classes with a base_uri defined.
 * Added an RDF::URI property type
 * Implemented #to_rdf and #to_uri for increased compatibility with the RDF.rb 
   ecosystem

## 0.0.1
 * Initial release
