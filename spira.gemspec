#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-
$:.unshift File.expand_path('../lib', __FILE__)
require 'spira/version'


Gem::Specification.new do |gem|
  gem.version            = Spira::VERSION.to_s
  gem.date               = Time.now.strftime('%Y-%m-%d')

  gem.name               = 'spira'
  gem.homepage           = 'https://ruby-rdf.github.io/spira/'
  gem.license            = 'Unlicense'
  gem.summary            = 'A framework for using the information in RDF.rb repositories as model objects.'
  gem.description        = 'Spira is a framework for using the information in RDF.rb repositories as model objects.'

  gem.authors            = ['Ben Lavender']
  gem.email              = 'blavender@gmail.com'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(AUTHORS README.md UNLICENSE VERSION) + Dir.glob('lib/**/*.rb')
  gem.require_paths      = %w(lib)
  gem.has_yardoc         = true if gem.respond_to?(:has_yardoc)

  gem.required_ruby_version      = '>= 2.6'
  gem.requirements               = []

  gem.add_runtime_dependency     'rdf',            '~> 3.2'
  gem.add_runtime_dependency     'rdf-isomorphic', '~> 3.2'
  gem.add_runtime_dependency     'promise',        '~> 0.3'
  gem.add_runtime_dependency     'activemodel',    '~> 6.1'
  gem.add_runtime_dependency     'activesupport',  '~> 6.1'
  gem.add_runtime_dependency     'i18n',           '~> 1.8'

  gem.add_development_dependency 'rdf-spec',      '~> 3.2'
  gem.add_development_dependency 'rdf-turtle',    '~> 3.2'
  gem.add_development_dependency 'rdf-vocab',     '~> 3.2'
  gem.add_development_dependency 'rspec',         '~> 3.10'
  gem.add_development_dependency 'rspec-its',     '~> 1.3'
  gem.add_development_dependency 'yard',          '~> 0.9'

  gem.post_install_message       = nil
end
