Resource URL is always a.b.c:<uri>


require 'moduler'
require 'moduler/specializable'

module Chef
  module ResourceDSL
    class Type
      extend Moduler::Specializable
      Moduler.inline do
        # We support:
        # type = Type|Module|Array[Type]|Hash[Type => Type]|Set[Type]
        #
        # type <type>
        # type <type>, <options> do
        #   ...
        # end
        # type <options> do
        #   ...
        # end
        #
        on_call do |base=nil, options={}, &block|
          if base.is_a?(Hash) && (base.size == 0 || base[0].is_a?(Symbol))
            base, options = nil, base
          end
          case base
          when Type
          when nil
            if options || block
          when Array
            if args.size == 0
              raise ""
            end
            options[:kind_of] ||= []
          when Hash
          when Set
          when Class
          end
          if args.first.is_a?(Type)
          if args || block
          super
        end
      end
    end

    class HashType < Type
      Moduler.inline do
        attribute :key_type, Type
        attribute :value_type, Type
      end
    end

    class ResourceType < StructType
    end

    class Resource
      extend Moduler::Specializable

      def self.from_id(id)
        new(id.is_a?(Hash) ? id : { id_attribute => id })
      end

      Moduler.inline do
        in_class do
          def self.type
            ResourceType
          end
        end
        attribute :attributes, Hash[String, Attribute]
        attribute :recipes
        attribute :container
        attribute :canonical_id, :readonly => true
      end
    end

    def namespace(name, *args, &block)
      moduler.define_module(name)
    end

    def resource(name, *args, &block)
      if name ==
      moduler.define_module(:Resource)
    end
  end

namespace :chef

Resource Types: chef.run.resource.type:<resource path>
- source: <resource path>
- from_id(id)
- get(id) - load resource attributes from the real resource
- attributes - attribute metadata
- resource_types

Resource: chef.run.resource:<resource url>
- resource_type
- canonical_id
- short_name
- recipes
- namespace:


Recipe: chef.run
-

Root: chef.run.root:<other resource url>
- root namespace, containing cookbooks and resource types instantiated from them
- cookbooks: loaded cookbooks

Cookbook: chef.run.cookbook:<source url>
- name, version, checksum
- depends_on <cookbooks>
- dependents <cookbooks>
- resource_types

Managed: <other resource url>
- name
-
- attributes
- run list


Run:
- cookbooks: loaded cookbooks
-

Cookbook:
- resource_types: paths to resource types
- files: paths to files

Resource Methods:
- resource_type.recipes
- resource_type.
- resource.context.resource_type
- resource.


Resource names are lowercase.

Syntax: <resource>/path   ->
Resource is always the top level thing
Chef Client Run:
- ->

Resource Instance:
-

Resource
    (Data about this particular instance)
    -> chef_cookbook/resource
