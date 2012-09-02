# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require "capistrano-stack/version"

Gem::Specification.new do |s|
  s.name            = "capistrano-stack"
  s.version         = Capistrano::Stack::VERSION
  s.authors         = ["Mikhail Mikhaliov"]
  s.email           = ["legiar@gmail.com"]
  s.homepage        = "http://github.com/legiar/capistrano-stack"
  s.description     = %q{TODO: Write a gem description}
  s.summary         = %q{TODO: Write a gem summary}
  s.license         = ["MIT"]

  s.files           = `git ls-files`.split($\)
  s.executables     = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files      = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths   = ["lib"]

  s.add_dependency  "capistrano", ">= 2.0.0"
  s.add_dependency  "rvm-capistrano"
end
