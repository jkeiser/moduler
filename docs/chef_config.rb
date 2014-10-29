# Short term needs:
# - scope for lazy that includes parents
# Medium term needs:
# - make PathString and Paths easy to create: allow specialization of type instances that actually works
#   - add scope and merging

require 'moduler'

class Chef
  class Config
    extend Moduler::Type::InlineStruct

    Path = Moduler::Type::PathType.new(store_as: String)

    # Config file to load (client.rb, knife.rb, etc. defaults set differently in knife, chef-client, etc.)
    attribute :config_file, Path, relative_to: lazy { config_dir }
    attribute :config_dir,  Path, relative_to: lazy { config_file },
                                  default:     lazy { is_set?(:config_file) ? '..' : [user_home, '.chef', '']}
    attribute :formatters, Array[Chef::Formatters::Base]
    attribute :chef_server, Struct do
      # Override the config dispatch to set the value of multiple server options simultaneously
      #
      # === Parameters
      # url<String>:: String to be set for all of the chef-server-api URL's
      #
      attribute :chef_server_url, URI, default: "https://localhost:443"
      attribute :node_name, String
      attribute :client_key, Path, relative_to: lazy { [ config_dir, 'keys' ] }
      attribute :http_retry_count, Fixnum, default: 5
      attribute :http_retry_delay, Fixnum, default: 5
    end

    attribute :client, Struct do
      attribute :daemonize, Boolean
      # The number of times the client should retry when registering with the server
      attribute :client_registration_retries, Fixnum, 5
      # The chef-client (or solo) lockfile.
      #
      # If your `file_cache_path` resides on a NFS (or non-flock()-supporting
      # fs), it's recommended to set this to something like
      # '/tmp/chef-client-running.pid'
      attribute :lockfile, Path, relative_to: lazy { file_cache_path }, default: "chef-client-running.pid"

      ## Daemonization Settings ##
      # What user should Chef run as?
      attribute :user, String
      attribute :group, String
      attribute :umask, Fixnum, 0022

      attribute :interval, Fixnum
      attribute :once, Boolean
      attribute :json_attribs, Hash, default: nil
      attribute :splay, Fixnum
      attribute :client_fork, Boolean, default: true
    end

    # The root where all local chef object data is stored.  cookbooks, data bags,
    # environments are all assumed to be in separate directories under this.
    # chef-solo uses these directories for input data.  knife commands
    # that upload or download files (such as knife upload, knife role from file,
    # etc.) work.
    attribute :chef_repo_path, Array[Path], relative_to: lazy { cache_path },
                                            default: lazy { is_set?(:cookbook_path) ? [ cookbook_path, '..' ] : '.' }

    # Location of acls on disk. String or array of strings.
    # Defaults to <chef_repo_path>/acls.
    # Only applies to Enterprise Chef commands.
    attribute :acl_path, Array[Path], relative_to: lazy { chef_repo_path }, default: 'acls'

    # Location of clients on disk. String or array of strings.
    # Defaults to <chef_repo_path>/acls.
    attribute :client_path, Array[Path], relative_to: lazy { chef_repo_path }, default: 'clients'

    # Location of cookbooks on disk. String or array of strings.
    # Defaults to <chef_repo_path>/cookbooks.  If chef_repo_path
    # is not specified, this is set to [/var/chef/cookbooks, /var/chef/site-cookbooks]).
    attribute :cookbook_path, Array[Path], relative_to: lazy { chef_repo_path }, default: lazy do
      is_set?(:chef_repo_path) ? 'cookbooks' : [ 'cookbooks', 'site-cookbooks' ]
    end

    # Location of containers on disk. String or array of strings.
    # Defaults to <chef_repo_path>/containers.
    # Only applies to Enterprise Chef commands.
    attribute :container_path, Array[Path], relative_to: lazy { chef_repo_path }, default: 'containers'

    # Location of data bags on disk. String or array of strings.
    # Defaults to <chef_repo_path>/data_bags.
    attribute :data_bag_path, Array[Path], relative_to: lazy { chef_repo_path }, default: 'data'

    # Location of environments on disk. String or array of strings.
    # Defaults to <chef_repo_path>/environments.
    attribute :environment_path, Array[Path], relative_to: lazy { chef_repo_path }, default: 'environments'

    # Location of groups on disk. String or array of strings.
    # Defaults to <chef_repo_path>/groups.
    # Only applies to Enterprise Chef commands.
    attribute :group_path, Array[Path], relative_to: lazy { chef_repo_path }, default: 'groups'

    # Location of nodes on disk. String or array of strings.
    # Defaults to <chef_repo_path>/nodes.
    attribute :node_path, Array[Path], relative_to: lazy { chef_repo_path }, default: 'nodes'

    # Location of roles on disk. String or array of strings.
    # Defaults to <chef_repo_path>/roles.
    attribute :role_path, Array[Path], relative_to: lazy { chef_repo_path }, default: 'roles'

    # Location of users on disk. String or array of strings.
    # Defaults to <chef_repo_path>/users.
    # Does not apply to Enterprise Chef commands.
    attribute :user_path, Array[Path], relative_to: lazy { chef_repo_path }, default: 'users'

    def self.find_chef_repo_path(cwd)
      # In local mode, we auto-discover the repo root by looking for a path with "cookbooks" under it.
      # This allows us to run config-free.
      path = cwd
      until File.directory?(PathHelper.join(path, "cookbooks"))
        new_path = File.expand_path('..', path)
        if new_path == path
          Chef::Log.warn("No cookbooks directory found at or above current directory.  Assuming #{Dir.pwd}.")
          return Dir.pwd
        end
        path = new_path
      end
      Chef::Log.info("Auto-discovered chef repository at #{path}")
      path
    end

    # Turn on "path sanity" by default. See also: http://wiki.opscode.com/display/chef/User+Environment+PATH+Sanity
    attribute :enforce_path_sanity, Boolean, default: true

    # Formatted Chef Client output is a beta feature, disabled by default:
    attribute :formatter, String, default: "null"

    attribute :knife, Struct do
      # An array of paths to search for knife exec scripts if they aren't in the current directory
      attribute :script_path, Array[Path]
    end

    attribute :windows_chef_root, Path, :default => 'C:\\chef'

    # The root of all caches (checksums, cache and backup).  If local mode is on,
    # this is under the user's home directory.
    attribute :cache_path, Path, default: lazy do
      if local_mode
        PathHelper.join(config_dir, 'local-mode-cache')
      else
        primary_cache_root = Chef::Platform.is_windows? ? "/var" : 'C:'
        primary_cache_path = (Path.new(primary_cache_root) / 'chef').to_s
        # Use /var/chef as the cache path only if that folder exists and we can read and write
        # into it, or /var exists and we can read and write into it (we'll create /var/chef later).
        # Otherwise, we'll create .chef under the user's home directory and use that as
        # the cache path.
        unless path_accessible?(primary_cache_path) || path_accessible?(primary_cache_root)
          secondary_cache_path = (Path.new(user_home) / '.chef').to_s
          Chef::Log.info("Unable to access cache at #{primary_cache_path}. Switching cache to #{secondary_cache_path}")
          secondary_cache_path
        else
          primary_cache_path
        end
      end
    end

    # Where cookbook files are stored on the server (by content checksum)
    attribute :checksum_path, Path, :relative_to => lazy { cache_path }, :default => "checksums"

    # Where chef's cache files should be stored
    attribute :file_cache_path, Path, :relative_to => lazy { cache_path }, :default => "cache"

    # Where backups of chef-managed files should go
    attribute :file_backup_path, Path, :relative_to => lazy { cache_path }, :default => "backup"

    # Returns true only if the path exists and is readable and writeable for the user.
    def self.path_accessible?(path)
      File.exists?(path) && File.readable?(path) && File.writable?(path)
    end

    # Valid log_levels are:
    # * :debug
    # * :info
    # * :warn
    # * :fatal
    # These work as you'd expect. There is also a special `:auto` setting.
    # When set to :auto, Chef will auto adjust the log verbosity based on
    # context. When a tty is available (usually becase the user is running chef
    # in a console), the log level is set to :warn, and output formatters are
    # used as the primary mode of output. When a tty is not available, the
    # logger is the primary mode of output, and the log level is set to :info
    attribute :log_level, Symbol, equal_to: [ :debug, :info, :warn, :fatal, :auto ], default: :auto

    # Logging location as either an IO stream or string representing log file path
    attribute :log_location, IO, default: STDOUT

    # Using `force_formatter` causes chef to default to formatter output when STDOUT is not a tty
    attribute :force_formatter, Boolean

    # Using `force_logger` causes chef to default to logger output when STDOUT is a tty
    attribute :force_logger, Boolean

    # toggle info level log items that can create a lot of output
    attribute :verbose_logging, Boolean, default: true

    attribute :diff_disabled, Boolean
    attribute :diff_filesize_threshold, Fixnum, default: 10000000
    attribute :diff_output_threshold, Fixnum, default: 1000000
    attribute :local_mode, Boolean

    attribute :pid_file, Path

    attribute :chef_zero, Struct do
      attribute :enabled, Boolean, :default => { local_mode }
      attribute :host, String, :default => 'localhost'
      attribute :port, :kind_of => [ Fixnum, Enumerable ], :default => 8889.upto(9999)
    end

    attribute :rest_timeout,     Fixnum, :default => 300
    attribute :yum_timeout,      Fixnum, :default => 900
    attribute :yum_lock_timeout, Fixnum, :default => 30
    attribute :solo, Boolean
    attribute :why_run, Boolean
    attribute :color, Boolean
    attribute :enable_reporting, Boolean, :default => true
    attribute :enable_reporting_url_fatals, Boolean

    # Policyfile is an experimental feature where a node gets its run list and
    # cookbook version set from a single document on the server instead of
    # expanding the run list and having the server compute the cookbook version
    # set based on environment constraints.
    #
    # Because this feature is experimental, it is not recommended for
    # production use. Developent/release of this feature may not adhere to
    # semver guidelines.
    attribute :use_policyfile, Boolean, false

    # Set these to enable SSL authentication / mutual-authentication
    # with the server

    # Client side SSL cert/key for mutual auth
    attribute :ssl_client_cert, Path
    attribute :ssl_client_key, Path

    # Whether or not to verify the SSL cert for all HTTPS requests. When set to
    # :verify_peer (default), all HTTPS requests will be validated regardless of other
    # SSL verification settings. When set to :verify_none no HTTPS requests will
    # be validated.
    attribute :ssl_verify_mode, Boolean, equal_to: [ :verify_peer, :verify_none ], default: :verify_peer

    # Whether or not to verify the SSL cert for HTTPS requests to the Chef
    # server API. If set to `true`, the server's cert will be validated
    # regardless of the :ssl_verify_mode setting. This is set to `true` when
    # running in local-mode.
    # NOTE: This is a workaround until verify_peer is enabled by default.
    attribute :verify_api_cert, Boolean, default: lazy { Chef::Config.local_mode }

    # Path to the default CA bundle files.
    attribute :ssl_ca_path, Path
    attribute :ssl_ca_file, Path, default: lazy do
      if Chef::Platform.windows? and embedded_path = embedded_dir
        cacert_path = Path.new(embedded_path).join(%w(ssl certs cacert.pem)).to_s
        cacert_path if File.exist?(cacert_path)
      else
        nil
      end
    end

    # A directory that contains additional SSL certificates to trust. Any
    # certificates in this directory will be added to whatever CA bundle ruby
    # is using. Use this to add self-signed certs for your Chef Server or local
    # HTTP file servers.
    attribute :trusted_certs_dir, Path, relative_to: lazy { config_dir }, default: "trusted_certs"

    # Where should chef-solo download recipes from?
    attribute :recipe_url, URI

    # Sets the version of the signed header authentication protocol to use (see
    # the 'mixlib-authorization' project for more detail). Currently, versions
    # 1.0 and 1.1 are available; however, the chef-server must first be
    # upgraded to support version 1.1 before clients can begin using it.
    #
    # Version 1.1 of the protocol is required when using a `node_name` greater
    # than ~90 bytes (~90 ascii characters), so chef-client will automatically
    # switch to using version 1.1 when `node_name` is too large for the 1.0
    # protocol. If you intend to use large node names, ensure that your server
    # supports version 1.1. Automatic detection of large node names means that
    # users will generally not need to manually configure this.
    #
    # In the future, this configuration option may be replaced with an
    # automatic negotiation scheme.
    attribute :authentication_protocol_version, :equal_to => %w(1.0 1.1), :default => "1.0"

    # This key will be used to sign requests to the Chef server. This location
    # must be writable by Chef during initial setup when generating a client
    # identity on the server.
    #
    # The chef-server will look up the public key for the client using the
    # `node_name` of the client.
    #
    # If chef-zero is enabled, this defaults to nil (no authentication).
    attribute :client_key, Path, :default => lazy { chef_zero.enabled ? nil : platform_specific_path("/etc/chef/client.pem") }

    # This secret is used to decrypt encrypted data bag items.
    attribute :encrypted_data_bag_secret, Path, :default => lazy do
      if File.exist?(platform_specific_path("/etc/chef/encrypted_data_bag_secret"))
        platform_specific_path("/etc/chef/encrypted_data_bag_secret")
      else
        nil
      end
    end

    # As of Chef 11.0, version "1" is the default encrypted data bag item
    # format. Version "2" is available which adds encrypt-then-mac protection.
    # To maintain compatibility, versions other than 1 must be opt-in.
    #
    # Set this to `2` if you have chef-client 11.6.0+ in your infrastructure.
    # Set this to `3` if you have chef-client 11.?.0+, ruby 2 and OpenSSL >= 1.0.1 in your infrastructure. (TODO)
    attribute :data_bag_encrypt_version, Fixnum, :equal_to => [ 1, 2, 3 ], :default => 1

    # When reading data bag items, any supported version is accepted. However,
    # if all encrypted data bags have been generated with the version 2 format,
    # it is recommended to disable support for earlier formats to improve
    # security. For example, the version 2 format is identical to version 1
    # except for the addition of an HMAC, so an attacker with MITM capability
    # could downgrade an encrypted data bag to version 1 as part of an attack.
    attribute :data_bag_decrypt_minimum_version, Fixnum, :default => 0

    # If there is no file in the location given by `client_key`, chef-client
    # will temporarily use the "validator" identity to generate one. If the
    # `client_key` is not present and the `validation_key` is also not present,
    # chef-client will not be able to authenticate to the server.
    #
    # The `validation_key` is never used if the `client_key` exists.
    #
    # If chef-zero is enabled, this defaults to nil (no authentication).
    attribute :validation_key, Path, :default => lazy { chef_zero.enabled ? nil : platform_specific_path("/etc/chef/validation.pem") }
    attribute :validation_client_name, String, :default => "chef-validator"

    # When creating a new client via the validation_client account, Chef 11
    # servers allow the client to generate a key pair locally and send the
    # public key to the server. This is more secure and helps offload work from
    # the server, enhancing scalability. If enabled and the remote server
    # implements only the Chef 10 API, client registration will not work
    # properly.
    #
    # The default value is `true`. Set to `false` to disable client-side key
    # generation (server generates client keys).
    attribute :local_key_generation, Boolean, default: true

    # Zypper package provider gpg checks. Set to true to enable package
    # gpg signature checking. This will be default in the
    # future. Setting to false disables the warnings.
    # Leaving this set to nil or false is a security hazard!
    attribute :zypper_check_gpg, Boolean

    # Report Handlers
    attribute :report_handlers, Array[Chef::Handler]

    # Event Handlers
    default :event_handlers, Array[Chef::EventDispatch::Base]

    # Exception Handlers
    default :exception_handlers, Array[Chef::Handler]

    # Start handlers
    default :start_handlers, Array[Chef::Handler]

    # Syntax Check Cache. Knife keeps track of files that is has already syntax
    # checked by storing files in this directory. `syntax_check_cache_path` is
    # the new (and preferred) configuration setting. If not set, knife will
    # fall back to using cache_options[:path], which is deprecated but exists in
    # many client configs generated by pre-Chef-11 bootstrappers.
    attribute :syntax_check_cache_path, Path, default: lazy { cache_options[:path] }

    # Deprecated:
    attribute :cache_options, default: lazy { { :path => Path.new(file_cache_path) / "checksums") } }

    # Set to false to silence Chef 11 deprecation warnings:
    attribute :chef11_deprecation_warnings, default: true

    # knife configuration data
    attribute :knife, Struct do
      attribute :ssh_port,            Fixnum
      attribute :ssh_user,            String
      attribute :ssh_attribute,       String
      attribute :ssh_gateway,         URI
      attribute :bootstrap_version,   String
      attribute :bootstrap_proxy,     URI
      attribute :bootstrap_template,  String, default: "chef-full"
      attribute :secret,              String
      attribute :secret_file,         Path
      attribute :identity_file,       Path
      attribute :host_key_verify,     String
      attribute :forward_agent,       String
      attribute :sort_status_reverse, Boolean
      attribute :hints,               Hash
    end

    def self.set_defaults_for_windows
      # Those lists of regular expressions define what chef considers a
      # valid user and group name
      # From http://technet.microsoft.com/en-us/library/cc776019(WS.10).aspx
      principal_valid_regex_part = '[^"\/\\\\\[\]\:;|=,+*?<>]+'
      attribute :user_valid_regex,  Array[Regexp], default: [ /^(#{principal_valid_regex_part}\\)?#{principal_valid_regex_part}$/ ]
      attribute :group_valid_regex, Array[Regexp], default: [ /^(#{principal_valid_regex_part}\\)?#{principal_valid_regex_part}$/ ]

      attribute :fatal_windows_admin_check, Boolean
    end

    def self.set_defaults_for_nix
      # Those lists of regular expressions define what chef considers a
      # valid user and group name
      #
      # user/group cannot start with '-', '+' or '~'
      # user/group cannot contain ':', ',' or non-space-whitespace or null byte
      # everything else is allowed (UTF-8, spaces, etc) and we delegate to your O/S useradd program to barf or not
      # copies: http://anonscm.debian.org/viewvc/pkg-shadow/debian/trunk/debian/patches/506_relaxed_usernames?view=markup
      attribute :user_valid_regex,  Array[Regexp], :default => [ /^[^-+~:,\t\r\n\f\0]+[^:,\t\r\n\f\0]*$/ ]
      attribute :group_valid_regex, Array[Regexp], :default => [ /^[^-+~:,\t\r\n\f\0]+[^:,\t\r\n\f\0]*$/ ]
    end

    # Those lists of regular expressions define what chef considers a
    # valid user and group name
    if Chef::Platform.windows?
      set_defaults_for_windows
    else
      set_defaults_for_nix
    end

    # This provides a hook which rspec can stub so that we can avoid twiddling
    # global state in tests.
    def self.env
      ENV
    end

    def self.windows_home_path
      env['SYSTEMDRIVE'] + env['HOMEPATH'] if env['SYSTEMDRIVE'] && env['HOMEPATH']
    end

    # returns a platform specific path to the user home dir if set, otherwise default to current directory.
    attribute :user_home, default: lazy { env['HOME'] || windows_home_path || env['USERPROFILE'] || Dir.pwd }

    # Enable file permission fixup for selinux. Fixup will be done
    # only if selinux is enabled in the system.
    attribute :enable_selinux_file_permission_fixup, Boolean, default: true

    # Use atomic updates (i.e. move operation) while updating contents
    # of the files resources. When set to false copy operation is
    # used to update files.
    attribute :file_atomic_update, Boolean, default: true

    # If false file staging is will be done via tempfiles that are
    # created under ENV['TMP'] otherwise tempfiles will be created in
    # the directory that files are going to reside.
    attribute :file_staging_uses_destdir, Boolean, default: true

    # Exit if another run is in progress and the chef-client is unable to
    # get the lock before time expires. If nil, no timeout is enforced. (Exits
    # immediately if 0.)
    attribute :run_lock_timeout, Fixnum

    # Number of worker threads for syncing cookbooks in parallel. Increasing
    # this number can result in gateway errors from the server (namely 503 and 504).
    # If you are seeing this behavior while using the default setting, reducing
    # the number of threads will help.
    attribute :cookbook_sync_threads, Fixnum, default: 10

    # At the beginning of the Chef Client run, the cookbook manifests are downloaded which
    # contain URLs for every file in every relevant cookbook.  Most of the files
    # (recipes, resources, providers, libraries, etc) are immediately synchronized
    # at the start of the run.  The handling of "files" and "templates" directories,
    # however, have two modes of operation.  They can either all be downloaded immediately
    # at the start of the run (no_lazy_load==true) or else they can be lazily loaded as
    # cookbook_file or template resources are converged which require them (no_lazy_load==false).
    #
    # The advantage of lazily loading these files is that unnecessary files are not
    # synchronized.  This may be useful to users with large files checked into cookbooks which
    # are only selectively downloaded to a subset of clients which use the cookbook.  However,
    # better solutions are to either isolate large files into individual cookbooks and only
    # include those cookbooks in the run lists of the servers that need them -- or move to
    # using remote_file and a more appropriate backing store like S3 for large file
    # distribution.
    #
    # The disadvantages of lazily loading files are that users some time find it
    # confusing that their cookbooks are not fully synchronzied to the cache initially,
    # and more importantly the time-sensitive URLs which are in the manifest may time
    # out on long Chef runs before the resource that uses the file is converged
    # (leading to many confusing 403 errors on template/cookbook_file resources).
    #
    attribute :no_lazy_load, Boolean, default: true

    # A whitelisted array of attributes you want sent over the wire when node
    # data is saved.
    # The default setting is nil, which collects all data. Setting to [] will not
    # collect any data for save.
    attribute :automatic_attribute_whitelist, Array[String], default: nil
    attribute :default_attribute_whitelist,   Array[String], default: nil
    attribute :normal_attribute_whitelist,    Array[String], default: nil
    attribute :override_attribute_whitelist,  Array[String], default: nil

    # Chef requires an English-language UTF-8 locale to function properly.  We attempt
    # to use the 'locale -a' command and search through a list of preferences until we
    # find one that we can use.  On Ubuntu systems we should find 'C.UTF-8' and be
    # able to use that even if there is no English locale on the server, but Mac, Solaris,
    # AIX, etc do not have that locale.  We then try to find an English locale and fall
    # back to 'C' if we do not.  The choice of fallback is pick-your-poison.  If we try
    # to do the work to return a non-US UTF-8 locale then we fail inside of providers when
    # things like 'svn info' return Japanese and we can't parse them.  OTOH, if we pick 'C' then
    # we will blow up on UTF-8 characters.  Between the warn we throw and the Encoding
    # exception that ruby will throw it is more obvious what is broken if we drop UTF-8 by
    # default rather than drop English.
    #
    # If there is no 'locale -a' then we return 'en_US.UTF-8' since that is the most commonly
    # available English UTF-8 locale.  However, all modern POSIXen should support 'locale -a'.
    attribute :internal_locale, String, default: lazy do
      begin
        locales = `locale -a`.split
        case
        when locales.include?('C.UTF-8')
          'C.UTF-8'
        when locales.include?('en_US.UTF-8')
          'en_US.UTF-8'
        when locales.include?('en.UTF-8')
          'en.UTF-8'
        when guesses = locales.select { |l| l =~ /^en_.*UTF-8$'/ }
          guesses.first
        else
          Chef::Log.warn "Please install an English UTF-8 locale for Chef to use, falling back to C locale and disabling UTF-8 support."
          'C'
        end
      rescue
        Chef::Log.warn "No usable locale -a command found, assuming you have en_US.UTF-8 installed."
        'en_US.UTF-8'
      end
    end

    # Force UTF-8 Encoding, for when we fire up in the 'C' locale or other strange locales (e.g.
    # japanese windows encodings).  If we do not do this, then knife upload will fail when a cookbook's
    # README.md has UTF-8 characters that do not encode in whatever surrounding encoding we have been
    # passed.  Effectively, the Chef Ecosystem is globally UTF-8 by default.  Anyone who wants to be
    # able to upload Shift_JIS or ISO-8859-1 files needs to mark *those* files explicitly with
    # magic tags to make ruby correctly identify the encoding being used.  Changing this default will
    # break Chef community cookbooks and is very highly discouraged.
    attribute :ruby_encoding, Encoding, default: Encoding::UTF_8

    # If installed via an omnibus installer, this gives the path to the
    # "embedded" directory which contains all of the software packaged with
    # omnibus. This is used to locate the cacert.pem file on windows.
    def self.embedded_dir
      Pathname.new(_this_file).ascend do |path|
        if path.basename.to_s == "embedded"
          return path.to_s
        end
      end

      nil
    end

    # Path to this file in the current install.
    def self._this_file
      File.expand_path(__FILE__)
    end
  end
end
