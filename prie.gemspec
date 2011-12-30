# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "prie/version"

Gem::Specification.new do |s|
  s.name        = "prie"
  s.version     = Prie::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Brennan Cheung"]
  s.email       = ["prie@brennancheung.com"]
  s.homepage    = ""
  s.summary     = %q{Postfix Ruby Interpreter for Embedding}
  s.description = %q{A fully extensible and flexible postfix language designed for embedding scripting capability into your applications.}

  s.rubyforge_project = "prie"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec", "~> 2.6"
  s.add_development_dependency "ruby-debug19"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "rb-fsevent"
  s.add_development_dependency "growl_notify"
end
