# frozen_string_literal: true

require_relative "lib/coordconver/version"

Gem::Specification.new do |spec|
  spec.name = "coordconver"
  spec.version = Coordconver::VERSION
  spec.authors = ["chenwei"]
  spec.email = ["cheenwe@gmail.com"]

  spec.summary = "百度(BD-09)/火星(GCJ-02)/地球(WGS-84)坐标系互转、度分秒互转、两点距离, 以及百度/高德地理编码"
  spec.description = "提供百度坐标(BD-09)、国测局坐标(GCJ-02)、地球坐标(WGS-84)之间的纯离线互转, 经纬度与度分秒互转, 两点球面距离计算; 并封装百度/高德 Web 服务 API 实现地址与坐标的相互转换。附带命令行工具。"
  spec.homepage = "https://github.com/cheenwe/coordconver"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7"

  spec.metadata = {
    "allowed_push_host" => "https://rubygems.org",
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/cheenwe/coordconver",
    "changelog_uri" => "https://github.com/cheenwe/coordconver/blob/master/CHANGELOG.md",
    "bug_tracker_uri" => "https://github.com/cheenwe/coordconver/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    files = `git ls-files -z`.split("\x0")
    # 兜底: 尚未纳入 git 追踪的新文件也打包
    files += Dir.glob("{lib/**/*.rb,exe/*,CHANGELOG.md}")
    files.uniq.reject do |f|
      f.match(%r{\A(?:test|spec|features)/}) || !File.exist?(f)
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
