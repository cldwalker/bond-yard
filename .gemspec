# -*- encoding: utf-8 -*-
require 'rubygems' unless Object.const_defined?(:Gem)
require File.dirname(__FILE__) + "/lib/bond/yard"

Gem::Specification.new do |s|
  s.name        = "bond-yard"
  s.version     = Bond::Yard::VERSION
  s.authors     = ["Gabriel Horner"]
  s.email       = "gabriel.horner@gmail.com"
  s.homepage    = "http://github.com/cldwalker/bond-yard"
  s.summary = "Generate completions from yard docs"
  s.description = "This bond plugin generates completions for gems that have been documented with yard."
  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project = 'tagaholic'
  s.has_rdoc = 'yard'
  s.rdoc_options = ['--title', "bond-yard #{Bond::Yard::VERSION} Documentation"]
  s.add_dependency 'yard', '>= 0.5.2'
  s.add_development_dependency 'bacon', '>= 1.1.0'
  s.add_development_dependency 'mocha', '>= 0.9.8'
  s.add_development_dependency 'mocha-on-bacon'
  s.add_development_dependency 'bacon-bits'
  s.files = Dir.glob(%w[{lib,test}/**/*.rb bin/* [A-Z]*.{txt,rdoc} ext/**/*.{rb,c} **/deps.rip]) + %w{Rakefile .gemspec}
  s.extra_rdoc_files = ["README.rdoc", "LICENSE.txt"]
  s.license = 'MIT'
end
