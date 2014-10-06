The Crazytown Project
=====================

The Crazytown Project aims to make cookbooks significantly easier to write, use, and customize, by flipping the model so that everything is a resource (recipes are second-level), and making resources incredibly easy to write and use.

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

    resource_attribute :config do
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


resource


Metal Roadmap:
- Kitchen 3.0:
- Infraspec: Test framework to point at Chef Server and auto-discover things
  - why-run for checking if ?
  - tests
