class AssociationReflection
  attr_reader :macro
  attr_reader :name
  attr_reader :options

  def initialize(macro, name, options = {})
    @macro = macro
    @name = name
    @options = options
  end

  def class_name
    @class_name ||= (options[:type] || derive_class_name).to_s
  end

  def klass
    @klass ||= class_name.constantize
  end

  private

  def derive_class_name
    name.to_s.camelize
  end
end
