Resource URL is always a.b.c:<uri>

In Chef, a resource is an *active resource representation*.

When the config has

debug is on, all resources gain source, line and file

chef.types
- url
- resource

chef.type resource: Base type
- `parent_types`: Parent types.
- `facade_module`: a Ruby module representing the type
- `facade_class`: a Ruby class representing the type
- `new(value)`: place this type in front of the given underlying value.
- <debug> `source`: source files and lines that contributed to this
- Standard events, transforms and validation

chef.type < chef.resource:

- array_type: < type
  - `element_type`: Element type.
- hash_type < type
- set_type < type
- struct_type < type

- resource_type < type, resource: The type of a resource.
  - `attributes`: the actual child attributes and types.
  - `resources`: child resources.
  - `recipes`: actions you can perform on the real resource.
  - `events`: events you can subscribe to
  - `resource_class`: the resource class.
  - `run`: "Run this resource."  By default, calls `resource_type.recipes['default']`.
  - `default_recipe`: the name of the default recipe.  Default: `put`
  - events:
    - `on_create_resource`: { :type => [:create|:reopen], :resource => :resource }
  - recipes:
    - `put`: create or patch the target class. <default>
    - `get`: fill with information from the target class.
    - `new_resource(*args, &block)`: create a new copy of the target module.
    - `get_resource(*args, &block)`: reopen the target module.

- merged_type: Takes care of precedence, naming, and such.
  - `base_type`: The base type to merge
  - `list_attribute`: Name of the "list of configs" attribute (Array[{Fixnum, base_type}])
  - computed attributes:
    - `precedence_names`: A list of precedence symbols and the precedence values to use for them: this will create simple methods to replace configs with a particular precedence value.
    - `take <name> <block>`:
    - `merge <name> <block>`: overrides the attribute with
  - recipes:
    - `apply`: create or modify the target module.
# NOTE: we reopen and merge the config *template*.

chef.runtime:
- context: information about the current resource.  Generally created on the fly
  when asked for.  Exists largely to give a clean namespace for things that the
  user might otherwise want to rename.
  - `id`: The ID of the resource.  Readonly.
  - `container`: The containing resource.  Readonly.
  - `instance`: The actual resource instance.  Readonly.
  - computed:
    - `id`: computed from the class.
    - `run`: run this resource.  Stored in the class.
    - `resource_type`: The resource type.
    - `url`: The resource URL relative to the Chef root.
    - `root`: The current Chef root (computed)
    - `dsl`: mixin of {context=self} + container.context.dsl + resource_type.attributes/recipes/events + instance

- container
  - `resource_types`: path_collection<resource_type>
  - computed:
    - `dsl`: DSL to access the given resource types

- root < resource_collection
  - `resource_types`: a list of loaded resource types
  - `config`: the configuration root.
  - `log`: the logger for this root.
  - `threads`: the set of thread pools for this root.
  - events:
    - `on_`

- file

- config_rb_resource_collection < path_collection<resource>
  - source: <file_resource>

- managed_node_resource_collection < path_collection<resource>
  - source: <file_resource>

chef.path:
- collection: < source
  -
  - computed
    - `dsl`: DSL to access the given paths
- source: A source of text data.  Extend this with your custom source.
  - get(content_id=nil)
  - content
  - Initializable with "path"
  - relative_to
- entry: A traversable directory.
  - delete
- recipe:
  - put(path, path_entry, recurse)
  - get(path, path_entry, recurse)
  - delete(path, path_entry, recurse)
  - chdir(path) - new path_root
- entry: Hash
  - `source`
  - `relative_path`
  - put(recurse) <can defer>
  - get(recurse) <can defer>
  -
- root < path_source:
  - path_source
  - base_path
  - content: path_entry
  recipe:
  - put(recurse)
  - get(recurse)
  - delete(recurse)
  - chdir(path): get a new path_source to which things will be relative


- loader
- resource_loader
  - `source`
  -

chef.objects:
- node:
  - source: <resource>
  - name:
  - attributes: <hash>
  - run_list
- managed_resource:
  - source: <node>
  - resources:
    - resource_url
    - desires_hash
    - recipe
    - instance
  - managers: Array[<user>]
  - computed: instances
- actor:
  - name
  - public_credentials
- client:

chef.config:
- config (hash_struct)

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

    #
    # The DSL we use to create resources.
    #
    # Creates a class with:
    # - type - leads back to this resource type
    # - attributes -
    class ResourceType
      include Moduler::DSL
      Moduler.inline do
        attribute :attributes, Hash[String, Attribute]
        attribute :recipes
        attribute :container
        attribute :canonical_id, :readonly => true
        attribute :resource_class
      end
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
      end
    end

    def namespace(name, *args, &block)
      moduler.new_module(name)
    end

    def resource(name, *args, &block)
      if name ==
      moduler.new_module(:Resource)
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
