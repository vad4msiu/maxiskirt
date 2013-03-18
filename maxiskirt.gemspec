# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "maxiskirt/version"

Gem::Specification.new do |s|
  s.name        = "maxiskirt"
  s.version     = Maxiskirt::VERSION
  s.summary     = "factory_girl, relaxed"
  s.description = "Test::Unit begot MiniTest; factory_girl begot Miniskirt, Miniskirt begot Midiskirt, Midiskirt begets Maxiskirt"

  s.authors     = ["vad4msiu"]
  s.email       = ["vad4msiu@gmail.com"]
  s.homepage    = "http://github.com/vad4msiu/maxiskirt"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # Development depensencies
  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "rake"

  # Runtime dependencies
  s.add_runtime_dependency "activesupport", RUBY_VERSION >= "1.9" ? ">= 2.2" : ">= 3.0"
end
