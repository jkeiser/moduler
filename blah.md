Summary

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
   - Provider -> Resource
   - Action -> Recipe
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



resource :file, file do
  attribute :mode, :default => 0644
  attribute :owner, :default => 'jkeiser'
end


apt.package
rpm.package

if system is apt
  resource :package, apt.package do
    attribute :version, :coerce => proc { |value| value.to_s }
  end
else
  resource :package, rpm.package
end

package 'mysql' do
  provider Apt::ProviderClass
  action :insall
end

apt-get install mysql
yum install mysql



attribute :num_webservser
attribute :

resource :my_server do
  attribute :name
  attribute :addresses, :singular => :address Array do
    element_type do
      attribute :street, String
      attribute :city, String
      attribute :state, :equal_to => [ 'CO', 'WA' ]
    end
  end
  attribute :ip_address

  recipe :create do
    my_server 'blah' do
      address do
        street ..
      end
      address do
        street ..
      end
    end
  end
end



node['normal']['']



resource :my_thing do
  attribute :name

  immediate :create do
    file 'x.txt'

    x = File.open('x.txt')

    file 'y.txt'
  end
end

immediate do
  file 'b.txt'
  my_thing 'blah'

end

resource :immediate, recipe do
  def add_resource(resource)
    resource.run
  end
  def run
  end
end

resource :parallel, recipe do

end


The Story
---------
1. Nested, specializable resources you can declare inline
2. Cookbooks have validatable, readable attributes with structure--validate attributes on upload, with array and nested attributes, no more "mess of hash crap."
3. Cookbooks are resources.  Recipes are resources.  Resources can have attributes, resources and recipes under them, and can be instantiated.
4. Specialize `small_machine` into your space.  Specialize `file` to include `owner`, `group` and `mode`:
   ```ruby
   resource :my_file, file do
     attribute :owner, :default => 'jkeiser'
     attribute :group, :default => 'wheel'
     attribute :mode,  :default => 0755

     recipe :screw_with_the_file do
       execute("rm -rf #{path}")
     end
   end
   ```

5. Run a recipe against another machine by doing `ssh('a.b.com:80', 'jkeiser', 'jkeiser.pem') do my_cookbook.on_machine_recipe.run end`
6. Make "drivers" and pick which one you want by bringing it into your namespace.  Get rid of the "hash of options" problem metal introduced:
   ```ruby
   # aws.rb
   my_region = aws.region('us-east-1')
   resource :small_machine, my_region.machine do
     attribute :ami, :default => 'ami-124872364'
     attribute :instance_typ
   end
   resource :large_machine, my_region.machine do
     attribute instance_type
   end

   small_machine 'webserver' do
   end
   large_machine 'db1' do
     recipe
   end

   # aws-cookbook.rb
   resource :machine, metal.machine do
     attribute :ami
     attribute :aws_ram, Fixnum
   end

   # os-cookbook.rb
   resource :machine, metal.machine do
     attribute :os_ram, Fixnum
   end


   # aws.rb
   os = aws.region('us-east-1')
   resource :small_machine, os.machine do
     attribute :aws_ram, :default > '2G'
   end
   resource :large_machine, os.machine do
     attribute :aws_ram, :default => '8G'
   end

   # openstack.rb
   os = openstack('http://sadfkjsadf')
   resource :small_machine, os.machine do
     attribute :os_ram, :default => '2G'
   end
   resource :large_machine, os.machine do
     attribute :os_ram, :default => '8G'
   end

   # mymachines.rb
   small_machine 'web' do
     recipe 'apache'
   end
   large_machine 'db' do
     recipe 'mysql'
   end
   ```

resource :file do
  consolidate_apt_packages :update do
  end
end

resource :immediate, recipe do
  def add_recipe(recipe)
    recipe.run
  end
  def run
  end
end

7. Nest resources for great justice:
   ```ruby
   recipe do

     github.organization 'opscode' do
       repository 'chef' do
         issue :issue_text => "repository #{name} sucks"
         issue :issue_text => 'blah'
       end
     end

   end
   ```
   recipe :name do
   end

   resource :immediate, recipe do
     def add_to_collection(resource)
       resource.run
     end
     def run_everything
     end
   end

   ```ruby
   attribute :url
   attribute :credentials
   attribute :addresses, Array do
     element_type do
       attribute :street
       attribute :city
       attribute :state, :equal_to => [ 'WA', 'CO' 'TX' ]
     end
   end

   resource :organization do
     attribute :organization_name

     resource :repository do
       attribute :repository_name

       resource :issue do
         attribute :id
         attribute :text
       end
     end
     resource :app_setting do
     end
   end
   ```

   resource :

   [
     "resource:github.ssh{machine=othermachine:22,username=jkeiser}.file{'/var/x.txt'}.on_change",
     ""
   ]
   ssh('othermachine:22', 'jkeiser') do
     call_recipe('setup_my_keys')
     file '/var/x.txt' do
       mode 066
     end
     execute ''
   end
   ```
8. "content source" things like file, csv_config, json_config, etc.--now config apis can give you a choice of what to write to the file by writing `attribute :httpd_config_source, source`.

- two-tier
- ruby rails mysql
- jboss redis mysql
- <loadbalanced webservers> <
data_bags/
cookbooks/
  aws_account.rb
  aws_account/region.rb
  aws_account/region/load_balancer.rb
  aws_account/region/update.rb
  aws_account/files


three_tier do
  load_balanced
  database :node
  monitoring :
  logging :
end




chef/
  resources/
    machine.rb

------

chef-repo/
  environments/
  cookbooks/
  roles/
  nodes/

  assets/
    open_stack/
    aws_account/


  topologies/
    my_app/
      us_west_a.rb


------

chef generate topology my_app/us_west_a

chef generate asset openstack_account



region_a/load_balancer_a.rb
webservers/



assets/
  types/
    account.rb
    load_balancer.rb
  accounts/
    github.rb
    aws/
      john.rb
      fred.rb
    openstack.rb
  load_balancers/
    elb.rb
    f5.rb


assets/
  account/
     github_account
     aws_account
  load_balancer

models
  applications/
    app_foobar
  topologies/
    app_foobar_aws_east
    multi_region_load_balanced_thing


aams
  packages
  configs
environments
  staging
    hosts
    config
  production
    hosts
    config


resources/topology.rb
resources/topology/my_topology

resource :my_topology




resource :ssh do
  attribute :server_name
  attribute :port
  attribute :username

  resource :file do
    attribute :path
  end

  resource :directory do
    attribute :path

    recipe :create do
      Dir.mkdir(path)
    end
  end
end


resource :httpd do
  resource :httpd_service do
    attribute :listen_ports, Array[Fixnum]
    attribute :package_name, String

    resource :service
  end
end

httpd.instance 'instance1' do
  service do
  end
  config do
  end
end
httpd.instance 'instance2' do
  service do
  end
  config do
  end
end

resource :instance do
  attribute :name, String

  resource :service do
  end

  resource :config do
  end
end

    config 'myconfig' do

    end
  end
  service 'instanc-2' do
  end
end



# github.rb
resource :github do
  attribute :github_server_url
  attribute :username
  attribute :num_server

  resource :organization do
    attribute :name
  end
end
