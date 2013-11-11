source "https://rubygems.org"
gemspec

gem "rdf",            :git => "git://github.com/ruby-rdf/rdf.git", :branch => "develop"

group "development" do
  gem "rake"
  gem "rdf-spec",    :git => "git://github.com/ruby-rdf/rdf-spec.git", :branch => "develop"
end

group "debug" do
  gem "debugger", :platforms => [:mri_19, :mri_20]
  gem "ruby-debug", :platforms => [:jruby]
end
