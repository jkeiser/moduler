The Crazytown Project
=====================

The Crazytown Project aims to make cookbooks significantly easier to write, use, and customize, by flipping the model so that everything is a resource (recipes are second-level), and making resources incredibly easy to write and use.

Summary
-------

Make resources
- Simpler
- Write inline and anywhere
- Nested and Scoped
- Extensible
- Universal (cookbooks and recipes are resources)

1. Inlineable Resources, Inlineable Recipes
   resource :httpd do
     attribute :max_connections, Fixnum

     resource :service do
     end

     recipe :create do
       ...
     end
   end
2. Providers And Actions No Longer Exist - Use Recipes Instead, Less Concepts
   - Provider+Action both go away, but are roughly replaced by Recipe
   - `converge_by` ->  `update_resource "description" do ... end`
3. Parseable Cookbook Public Interface: Cookbooks Are Resources
   - attribute :blah means
   - "httpd" is top level namespace for httpd cookbook: httpd.service, httpd.config, etc.
   - "httpd(:path => '/var/opt/blah')"
   - We know all the resources that can be instantiated, on down the line.
   - A run list is just a list of the instantiated recipes you want to run (with
     attributes).
   - Cookbook interfaces can be emitted
4. More Flexible Resource Instantiation
   - name can be defaulted (my_resource do ... end)
   - a.b.c.d
   - file '/var/www/x.txt', :mode => 0577
5. Powerful Attribute Syntax
   - attribute :addresses, :singular => :address, Array do
       element_type do
         attribute :street, String
         attribute :city, String
         attribute :state, :equal_to => %w(CO WA TX)
       end
     end
6. Recipe Model More Intelligible
   - A recipe "handles" resources. A recipe adds a "tree" of resources describing your system, and then its job is to make it happen.  Different recipes handle them differently.  They could:
     - Run all of them at the end
     - Pass them directly to the parent recipe to execute
     - Run them immediately
     - Run them immediately in parallel
     - Run the model in a complex way
   - Recipes are resources.  When you make a recipe resource it's added to your parent recipe.
7. Nested Scopes
   - Contained objects have access to parents (github.organization.repository.issue)
   - Recipes have direct access to their resource (because it is a resource contained in the parent)
   - "Enter that machine's scope and use its resources to do stuff": `ssh do file ... execute ... end`
   - Clear model: root scope -> cookbook scope -> resource -> recipe
8. Specialization
   - Make your own slightly different copy of a resource
   - Add defaults to a resource (file mode, owner, group)
9. Awesome "Driver Model"
   - file = windows.file or unix.file
   - machine = aws.region('us-east-1').machine,
   - Add any actual attributes you want to the specific implementation
   - Assign the implementation into your cookbook / recipe
   - Use it

Principles
- Low cost to move
  - Recipes work exactly the same
  - Resource syntax nearly identical to LWRP resource
  - "Chef 12 cookbooks" and "Chef 13 cookbooks" can use each other's resources and recipes
- Low cost to go from writing recipes to writing resources
  - Introduce as few concepts as possible
- Pleasing to Rubyists: drops you as close to Ruby as possible without exposing it.
  - Definitions like "resource" open up a class run in the resource's class.  "recipe" runs in the recipe's instance.
- Easy to debug
  - Error messages
  - Backtraces should make sense, particularly the top line
  - Wipe +method_missing+ from the face of the earth
  - Logging takes a front seat
- Testable
  - Nothing you reference is static.  Config and logging are instances.
  - Resources can be created and used without an underlying system
- Easy to reason about
  - System built out of resources: cookbook sync, policy load, recipe run
  - Reduced number of concepts overall
    - No providers or actions
    - Attributes are reified
    - Recipes and cookbooks are resources with some behavior
  - Everything is a resource (referenceable, instantiable, specializable, contains attributes+subresources)
  - Resources describe themselves and are inspectable

- Make resources primary, not recipes (start in resource mode)
- Make resources definable inline

- Make composition super easy
  ```ruby
  # Content can be a file, a template, or any file source
  # In "system"
  resource :types do
    resource :content do
    end
  end

  resource :template, :file do
  end

  resource :httpd do
    attribute :path, types.path
    attribute :config_path, types.path, :default => "conf", :relative_to => path

    resource :config do
      attribute :path, types.path do
        default "httpd.conf"
        relative_to config_path
      end
      # types.content can be a string, a template, or any file source
      attribute :data, types.content do
        reopen true
        default do
          file.template 'httpd.conf' do

          end
        end
      end

      # When you want to run:
      recipe do
        path.upload(data)
      end
    end

    resource_attribute :service, system.service do
      attribute :name, :default => 'httpd'
      attribute :
    end
    resource :
  end

  resource :rails_app do
    attribute :target_httpd, httpd
    attribute :source, system.file
  end

  recipe :default do
    httpd do
      config do
      end
    end.run
    config.
    httpd.apply
  end
  ```
- Make resources namespaced and nestable
  ```ruby
  aws.region('us-east-1').machine '' {  }
  github.organization('opscode').repository 'chef'
  httpd.service.start
  ```
- Make specialization easy
  ```ruby
  resource :small_machine, metal.machine do
    machine_options { 'ami' => 'ami-23423423' }
  end
  ```
- Add better validation to resources
  ```ruby
  resource :house do
    attribute :addresses, ArrayType do
      element_type do
        attribute :street, String
        attribute :city, String
        attribute :state, :equal_to => %w(WA CO TX NC)
      end
    end
  end
  ```
- Make recipe run logic customizable (parallel, immediate, serial, custom ...)
  ```ruby
  resource :immediate_recipe, chef.recipe do
    method :on_add_resource do |resource|
      if resource.type.name == 'chef.file'
        resource.run
      end
    end
    method :run do
      # We already ran
    end
  end
  ```

Goals
-----
- Structured cookbook attributes
- Documentation for cookbook and resource attributes
- Structured, analyzable, readable, predictable resources.
- Structured thinking about resources -> more reusable components
- Specializable APIs (aws.machine, )
- User customizations (machine -> small_machine)
- Versioned APIs
- Manage external things
- Generalized Input (chef.node(file | url))
- Multiple Languages?

Plans
-----
- Moduler type system
- Config API revamp:
  - type validation
  - better nesting
  - dynamic setters and getters
  - explicit lazy and non-lazy defaults
  - dynamically loadable config definitions
  - strict by default
- Resource API
- Recipe API
- File Resource API
- Execute Resource API
- Cheffish as a Resource API - resources taking arbitrary sources
- knife upload/download/diff against Cheffish - use for cookbooks
- Policy runner
  - Take in a chef.node
  - Load policy
  - Load cookbooks into a cache for the policy
- Backcompat Uploader
- Org Defaults resource API
- chef-zero serving Cheffish
- Ohai as resources
- Plugin Loading:
  - Autoloading sources
  - Knife plugins as resources?
  - Autoloading cookbooks?

A Cookbook Is Code
------------------

Cookbooks are libraries.  
The Experience
--------------

When you sit down to a crazytown cookbook, the first thing you do is open `cookbookname.rb`.  Your blank screen is now in a *resource definition*.  There is no libraries, there is no resources, there is no providers.

###


resource


Metal Roadmap:
- Kitchen 3.0:
- Infraspec: Test framework to point at Chef Server and auto-discover things
  - why-run for checking if ?
  - tests
