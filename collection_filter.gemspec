# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'collection_filter/version'

Gem::Specification.new do |gem|
  gem.name          = "collection_filter"
  gem.version       = CollectionFilter::VERSION
  gem.authors       = ["Toru KAWAMURA"]
  gem.email         = ["tkawa@4bit.net"]
  gem.description   = %q{Helps to make a simple filter in Filtered Collection pattern for Rails}
  gem.summary       = %q{Helps to make a simple filter in Filtered Collection pattern for Rails}
  gem.homepage      = "https://github.com/tkawa/collection_filter"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'railties', '~> 3.1'
  gem.add_dependency 'activerecord', '~> 3.1'
end
