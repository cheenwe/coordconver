# frozen_string_literal: true

require_relative "lib/coordconver/version"

Gem::Specification.new do |spec|
  spec.name = "coordconver"
  spec.version = Coordconver::VERSION
  spec.authors = ["chenwei"]
  spec.email = ["cheenwe@gmail.com"]

  spec.summary = "百度(BD-09)/火星(GCJ-02)/地球(WGS-84)坐标系互转、球面几何、高斯-克吕格投影, 以及百度/高德/腾讯地理编码"
  spec.description = "纯离线实现百度坐标(BD-09)、国测局坐标(GCJ-02)、地球坐标(WGS-84)互转(含厘米级精确逆变换), 两点距离/方位角/偏移点, 经纬度与度分秒互转, WKT/GeoJSON 互转, 高斯-克吕格投影正反算; 并封装百度/高德/腾讯 Web 服务 API 实现地址与坐标互转, 支持多 key 自动轮询与进程内缓存。附带命令行工具。"
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
