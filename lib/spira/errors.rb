module Spira
  class Errors

    def initialize
      @errors = {}
    end

    def empty?
      @errors.all? do |field, errors| errors.empty? end
    end

    def any?
      !empty?
    end

    def any_for?(property)
      !(@errors[property].nil?) && !(@errors[property].empty?)
    end
  
    def add(property, problem)
      @errors[property] ||= []
      @errors[property].push problem
    end

    def for(property)
      @errors[property]
    end

    def clear
      @errors = {}
    end

    def each
      @errors.map do |property, problems|
        problems.map do |problem|
          property.to_s + " " + problem  
        end
      end.flatten
    end


  end
end
