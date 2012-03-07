require "active_model"

module Spira

  ##
  # Spira::Base aims to perform similar to ActiveRecord::Base
  # You should inherit your models from it.
  #
  class Base
    extend ActiveModel::Callbacks
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include Spira::Resource

    define_model_callbacks :save, :destroy, :create, :update, :validation

    class << self
      def find(scope, args = {})
        conditions = args[:conditions] || {}
        options = args.except(:conditions)

        limit = options[:limit] || -1

        case scope
        when :first
          find_all(conditions, :limit => 1).first
        when :all
          find_all(conditions, :limit => limit)
        else
          find_by_id scope
        end
      end

      def all(args = {})
        find(:all, args)
      end

      def first(args = {})
        find(:first, args)
      end


      private

      def find_by_id id
        self.for id
      end

      def find_all conditions, options = {}
        patterns = [[:subject, RDF.type, type]]
        conditions.each do |name, value|
          patterns << [:subject, properties[name][:predicate], value]
        end

        q = RDF::Query.new do
          patterns.each do |pat|
            pattern pat
          end
        end

        [].tap do |results|
          repository_or_fail.query(q) do |solution|
            break if options[:limit].zero?
            results << self.for(solution[:subject])
            options[:limit] -= 1
          end
        end
      end
    end

    def id
      new_record? ? nil : subject.path.split(/\//).last
    end

    # A resource is considered to be new
    # when its definition ("resource - RDF.type - X") is not persisted,
    # although its properties may be in the storage.
    def new_record?
      !self.class.all.detect{|rs| rs.subject == subject }
    end

    def destroyed?
      @destroyed
    end

    def persisted?
      !(new_record? || destroyed?)
    end

    def save(*)
      if run_callbacks(:validation) { validate }
        run_callbacks :save do
          # "create" callback is triggered only when persisting a resource definition
          persistance_callback = new_record? && type ? :create : :update
          run_callbacks persistance_callback do
            persist!
          end
        end
        self
      else
        # return nil if could not save the record
        # (i.e. there are validation errors)
        nil
      end
    end

    def save!
      save || raise(ValidationError, "Could not save #{self.inspect} due to validation errors: " + errors.each.join(';'))
    end

    def destroy(*args)
      run_callbacks :destroy do
        (@destroyed ||= destroy!(*args)) && !!freeze
      end
    end

    def update_attributes(attributes, options = {})
      update(attributes)
      save
    end
  end
end
