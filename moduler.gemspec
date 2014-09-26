$:.unshift(File.dirname(__FILE__) + '/lib')
require 'moduler/version'

Gem::Specification.new do |s|
  s.name = 'moduler'
  s.version = Moduler::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = 'Simple, extensible and powerful DSL for creating classes and modules'
  s.description = s.summary
  s.author = 'John Keiser'
  s.email = 'john@johnkeiser.com'
  s.homepage = 'http://johnkeiser.com'
  s.license = 'Apache 2.0'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'

  s.bindir       = 'bin'
  s.executables  = []
  s.require_path = 'lib'
  s.files = %w(LICENSE README.md Rakefile) + Dir.glob('{lib,spec}/**/*')
end
