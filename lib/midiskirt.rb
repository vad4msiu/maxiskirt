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

Midiskirt = Struct.new(:__name__, :__klass__, :__parent__, :__params__)

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
      klass = options.delete(:class) || name
      parent = options.delete(:parent)

      @factories[name] = new(name, klass, parent, {})

      yield(@factories[name])
    end

    # Initialize and setup class from factory.
    #
    # You can override default factory settings, by passing them
    # as second argument.
    def build(name, params = {})
      factory    = @factories[name.to_s]

      klass      = factory.__klass__
      parent     = factory.__parent__
      attributes = attributes_for(name, params)

      # If parent set, then merge parent template with current template
      if parent
        klass = @factories[parent.to_s].__klass__
      end

      # Convert klass to real Class
      klass = klass.is_a?(Class) ? klass : klass.to_s.classify.constantize

      object = klass.new

      attributes.each do |name, value|
        object.send(:"#{name}=", value)
      end

      return object
    end

    def attributes_for(name, params_for_replace = {})
      params_for_replace = params_for_replace.symbolize_keys

      factory = @factories[name.to_s]

      klass  = factory.__klass__
      parent = factory.__parent__
      params = factory.__params__

      parent_params = if parent
        @factories[parent.to_s].__params__
      else
        {}
      end

      attributes = {}

      merged_params = parent_params.merge(params).merge(params_for_replace)
      merged_params.each do |name, value|
        attributes[name] = case value
        when String
          value.sub(/%\d*d/) { |d|
            d % (@sequence[klass] += 1)
          } % attributes
        when Proc
          value.call
        else
          value.duplicable? ? value.dup : value
        end
      end

      return attributes
    end

    # Create and save new factory product
    def create(name, params = {})
      build(name, params).tap { |record| record.save! }
    end
  end

  # Capture method calls, and save it to factory attributes
  def method_missing(name, value = nil, &block)
    __params__.merge!(name => block || value)
    value # Return value to be able to use chaining like: f.password f.password_confirmation("something")
  end
end

# Shortcut to Midiskirt#create
def Midiskirt(name, params = {})
  Midiskirt.create(name, params)
end

unless Object.const_defined? :Factory
  Factory = Midiskirt
  alias Factory Midiskirt
end