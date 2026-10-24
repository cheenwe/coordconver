# frozen_string_literal: true

module Coordconver
  module Geo
    # 全局配置。支持两种写法:
    #
    #   # 推荐: 全局配置块, key 支持数组以实现多 key 轮询
    #   Coordconver.configure do |config|
    #     config.baidu_map_aks = ["你的百度ak1", "你的百度ak2"]
    #     config.gaode_map_keys = ["你的高德key1", "你的高德key2"]
    #     # 可选: 百度 SN 校验(仅当 AK 类型为"SN 校验"时需要), 服务端 AK 用 IP 白名单则无需配置
    #     config.baidu_sn = "你的百度SK"
    #     # 可选: 超时(秒)
    #     config.open_timeout = 5
    #     config.read_timeout = 10
    #   end
    #
    #   # 兼容旧写法
    #   Coordconver::Client.new(["百度ak"], ["高德key"])
    module Configuration
      extend self

      DEFAULT_MAP_OPTIONS = {
        baidu_base_url: "https://api.map.baidu.com",
        gaode_base_url: "https://restapi.amap.com/v3",
        open_timeout: 5,
        read_timeout: 10
      }.freeze

      attr_reader :settings

      def configured?
        !@settings.nil?
      end

      def init(baidu_map_aks = nil, gaode_map_keys = nil, options = {})
        @settings = DEFAULT_MAP_OPTIONS.merge(
          baidu_map_aks: Array(baidu_map_aks).compact.reject(&:empty?),
          gaode_map_keys: Array(gaode_map_keys).compact.reject(&:empty?)
        ).merge(options)
        self
      end

      def reset!
        @settings = nil
      end

      def [](key)
        settings[key]
      end

      def method_missing(name, *args)
        if name.to_s.end_with?("=") && settings.key?(name.to_s.chomp("=").to_sym)
          settings[name.to_s.chomp("=").to_sym] = args.first
        else
          super
        end
      end

      def respond_to_missing?(name, include_private = false)
        (name.to_s.end_with?("=") && settings.key?(name.to_s.chomp("=").to_sym)) || super
      end

      def settings
        @settings or raise ConfigurationError, "尚未配置地图 API key。请先执行 Coordconver.configure { |c| c.baidu_map_aks = [...]; c.gaode_map_keys = [...] } 或 Coordconver::Client.new([百度ak数组], [高德key数组])"
      end

      # 随机取一个 key, 避免单 key 超额
      def sample_baidu_ak
        aks = settings[:baidu_map_aks]
        raise ConfigurationError, "未配置百度地图 AK (baidu_map_aks)" if aks.empty?

        aks.sample
      end

      def sample_gaode_key
        keys = settings[:gaode_map_keys]
        raise ConfigurationError, "未配置高德地图 Key (gaode_map_keys)" if keys.empty?

        keys.sample
      end
    end
  end
end
