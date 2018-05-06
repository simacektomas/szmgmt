lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "szmgmt/version"

Gem::Specification.new do |spec|
  spec.name          = "szmgmt"
  spec.version       = SZMGMT::VERSION
  spec.authors       = ["Tomas Simacek"]
  spec.email         = ["simacektomas@volny.cz"]

  spec.summary       = %q{Gem providing ruby library for management of Solaris zones.}
  spec.description   = %q{This gem supports management of Oracle Solaris zones. It provides function for deploying, backuping and migrating zones on hosts.}
  spec.homepage      = "https://github.com/simactom/szmgmt"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_dependency "parallel", '~> 1.12', '>= 1.12.1'
  spec.add_dependency "thor", '~> 0.20.0'
  spec.add_dependency "json-schema", '~> 2.8', '>= 2.8.0'
  spec.add_dependency "net-ssh", '~> 4.2', '>= 4.2.0'
  spec.add_dependency "unix-crypt", '~> 1.3', '>= 1.3.0'

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end