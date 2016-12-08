# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'coordconver'

Gem::Specification.new do |spec|
  spec.name          = "coordconver"
  spec.version       = Coordconver::VERSION
  spec.authors       = ["chenwei"]
  spec.email         = ["cheenwe@gmail.com"]

  spec.summary       = %q{坐标转换/Coordconver}
  spec.description   = %q{提供了百度坐标（BD09）、国测局坐标（火星坐标，GCJ02）、和WGS84坐标系之间的转换.}
  spec.homepage      = "https://github.com/cheenwe/coordconver"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
end
