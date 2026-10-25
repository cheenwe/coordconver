# frozen_string_literal: true

require "coordconver/version"
require "coordconver/errors"
require "coordconver/coordconver"
require "coordconver/degree"
require "coordconver/formats"
require "coordconver/projection"
require "coordconver/geo/configuration"
require "coordconver/geo/key_pool"
require "coordconver/geo/cache"
require "coordconver/geo/api"
require "coordconver/geo/client"
require "coordconver/geo/baidu"
require "coordconver/geo/gaode"
require "coordconver/geo/tencent"
require "coordconver/utils/http"
require "coordconver/utils/request"

module Coordconver
  # 坐标系转换/距离/方位角等方法已直接定义在 Coordconver 单例上,
  # 如 Coordconver.wgs_gcj(lng, lat) / Coordconver.distance(...) / Coordconver.bearing(...)
  extend Degree
  extend Formats
  extend Projection

  # 便捷常量别名, 兼容 Coordconver::Baidu / Coordconver::Gaode 等用法
  Baidu = Geo::Baidu
  Gaode = Geo::Gaode
  Tencent = Geo::Tencent
  Client = Geo::Client
  Configuration = Geo::Configuration
end
