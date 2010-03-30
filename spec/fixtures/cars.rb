
# These classes are to test finding based on rdfs.type


class Cars < RDF::Vocabulary('http://example.org/cars/')
  property :car
  property :van
  property :car1
  property :van
  property :station_wagon
  property :unrelated_type
end


class Car

  include Spira::Resource

  type Cars.car

  property :name, RDFS.label, String

end

class Van

  include Spira::Resource

  type Cars.van

  property :name, RDFS.label, String

end
