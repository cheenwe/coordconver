# frozen_string_literal: true

module Coordconver
  module Geo
    # 初始化配置。保留旧写法, 也可用 Coordconver.configure 块:
    #   Coordconver::Client.new(["百度ak1", "百度ak2"], ["高德key1"])
    class Client
      def initialize(baidu_map_aks = [], gaode_map_keys = [], options = {})
        Configuration.init(baidu_map_aks, gaode_map_keys, options)
      end
    end
  end

  module_function

  # 全局配置块:
  #   Coordconver.configure do |config|
  #     config.baidu_map_aks = ["ak1"]
  #     config.gaode_map_keys = ["key1"]
  #   end
  def configure
    Geo::Configuration.init unless Geo::Configuration.configured?
    yield Geo::Configuration
  end
end
