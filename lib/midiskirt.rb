require 'active_support/inflector'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/object/duplicable'

# Factory girl, relaxed.
#
#   Factory.define :user do |f|
#     f.login 'johndoe%d'                          # Sequence.
#     f.email '%{login}@example.com'               # Interpolate.
#     f.password f.password_confirmation('foobar') # Chain.
#   end
#
#   Factory.define :post do |f|
#     f.user { Factory :user }                     # Blocks, if you must.
#   end

Midiskirt = Struct.new(:__name__, :__klass__, :__parent__, :__attrs__)

class Midiskirt
  undef_method *instance_methods.grep(/^(?!__|object_id)/)
  private_class_method :new # "Hide" constructor from world

  # Do not use class variable, as it will be shared among all childrens and
  # can be unintentionally changed.
  @factories = {}
  @sequence = Hash.new(0)

  class << self
    # Define new factory with given name. New instance of Midiskirt
    # will be passed as argument to given block.
    #
    # Options are:
    # * class - name of class to be instantiated. By default is same as name
    # * parent - name of parent factory
    def define(name, options = {})
      name = name.to_s

      # Get class name from options or use name
      klass = options.delete(:class) { name }
      parent = options.delete(:parent)

      yield(@factories[name] = new(name, klass, parent, {}))
    end

    # Initialize and setup class from factory.
    #
    # You can override default factory settings, by passing them
    # as second argument.
    def build(name, attrs = {})
      factory    = @factories[name.to_s]

      klass      = factory.__klass__
      parent     = factory.__parent__
      attributes = attributes_for(name, attrs)
      p attributes

      # If parent set, then merge parent template with current template
      if parent
        klass = @factories[parent.to_s]._factory.__klass__
      end

      # Convert klass to real Class
      klass = klass.is_a?(Class) ? klass : klass.to_s.classify.constantize

      klass.new do |record|
        attributes.each do |name, value|
          # Call proc if value is proc or use copy of existent value if
          # it can be duplicated
          value = if value.kind_of?(Proc)
            (value.arity > 0) ? value.call(record) : value.call
          else
            value.duplicable? ? value.dup : value
          end

          record.send(:"#{name}=", value)
        end
      end
    end

    def attributes_for(name, attrs = {})
      factory    = @factories[name.to_s]

      klass      = factory.__klass__
      parent     = factory.__parent__
      attributes = factory.__attrs__

      # Create copy of attributes
      attributes = attributes.dup

      if parent
        attributes = attributes_for(@factories[parent.to_s]).merge(attributes)
      end

      attributes.merge!(attrs).symbolize_keys!

      # Interpolate attributes
      attributes.each do |name, value|
        if value.kind_of? String
          attributes[name] = value.sub(/%\d*d/) { |d|
            d % (@sequence[klass] += 1)
          } % attributes
        end
      end

      return attributes
    end

    # Create and save new factory product
    def create(name, attrs = {})
      build(name, attrs).tap { |record| record.save! }
    end
  end

  # Capture method calls, and save it to factory attributes
  def method_missing(name, value = nil, &block)
    __attrs__.merge!(name => block || value)
    value # Return value to be able to use chaining like: f.password f.password_confirmation("something")
  end
end

# Shortcut to Midiskirt#create
def Midiskirt(name, attrs = {})
  Midiskirt.create(name, attrs)
end

unless Object.const_defined? :Factory
  Factory = Midiskirt
  alias Factory Midiskirt
end