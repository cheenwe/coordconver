# frozen_string_literal: true

require "coordconver/version"
require "coordconver/errors"
require "coordconver/coordconver"
require "coordconver/degree"
require "coordconver/geo/configuration"
require "coordconver/geo/client"
require "coordconver/geo/baidu"
require "coordconver/geo/gaode"
require "coordconver/utils/http"
require "coordconver/utils/request"

module Coordconver
  # 坐标系转换与距离计算的方法已直接定义在 Coordconver 单例上,
  # 如 Coordconver.wgs_gcj(lng, lat) / Coordconver.distance(...)
  extend Degree

  # 便捷常量别名, 兼容 Coordconver::Baidu / Coordconver::Gaode 等用法
  Baidu = Geo::Baidu
  Gaode = Geo::Gaode
  Client = Geo::Client
  Configuration = Geo::Configuration
end
