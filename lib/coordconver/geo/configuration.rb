# frozen_string_literal: true

module Coordconver
  module Geo
    # 全局配置。支持两种写法:
    #
    #   # 推荐: 全局配置块, key 支持数组以实现多 key 轮询
    #   Coordconver.configure do |config|
    #     config.baidu_map_aks = ["你的百度ak1", "你的百度ak2"]
    #     config.gaode_map_keys = ["你的高德key1", "你的高德key2"]
    #     config.tencent_map_keys = ["你的腾讯key1"]
    #     # 可选: 百度 SN 校验(仅当 AK 类型为"SN 校验"时需要), 服务端 AK 用 IP 白名单则无需配置
    #     config.baidu_sn = "你的百度SK"
    #     # 可选: 进程内缓存地理编码结果, 节省配额 (默认 false)
    #     config.cache = true
    #     config.cache_ttl = 3600      # 缓存秒数, 默认 3600
    #     config.cache_size = 1024     # 缓存条目上限, 默认 1024 (LRU 淘汰)
    #     # 可选: 超时(秒)
    #     config.open_timeout = 5
    #     config.read_timeout = 10
    #   end
    #
    #   # 兼容旧写法
    #   Coordconver::Client.new(["百度ak"], ["高德key"], tencent_map_keys: ["腾讯key"])
    module Configuration
      extend self

      DEFAULT_MAP_OPTIONS = {
        baidu_base_url: "https://api.map.baidu.com",
        gaode_base_url: "https://restapi.amap.com/v3",
        tencent_base_url: "https://apis.map.qq.com/ws",
        open_timeout: 5,
        read_timeout: 10,
        cache: false,
        cache_ttl: 3600,
        cache_size: 1024
      }.freeze

      PROVIDER_KEY_FIELD = {
        baidu: :baidu_map_aks,
        gaode: :gaode_map_keys,
        tencent: :tencent_map_keys
      }.freeze

      attr_reader :settings

      def configured?
        !@settings.nil?
      end

      def init(baidu_map_aks = nil, gaode_map_keys = nil, options = {})
        tencent_keys = Array(options.delete(:tencent_map_keys))
        @settings = DEFAULT_MAP_OPTIONS.merge(
          baidu_map_aks: Array(baidu_map_aks).compact.reject(&:empty?),
          gaode_map_keys: Array(gaode_map_keys).compact.reject(&:empty?),
          tencent_map_keys: tencent_keys.compact.reject(&:empty?)
        ).merge(options)
        self
      end

      def reset!
        @settings = nil
        KeyPool.reset!
        Cache.clear!
      end

      def [](key)
        settings[key]
      end

      # 按 provider (:baidu/:gaode/:tencent) 取可用 key 数组, 未配置时抛出清晰错误
      def keys_for(provider)
        field = PROVIDER_KEY_FIELD[provider]
        raise ArgumentError, "未知的服务商: #{provider.inspect}" unless field

        keys = settings[field]
        raise ConfigurationError, "未配置 #{provider} 的 key (#{field}), 请通过 Coordconver.configure 或 Coordconver::Client.new 设置" if keys.empty?

        keys
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

      # 兼容旧接口: 取一个 key (现为实现为轮询)
      def sample_baidu_ak
        KeyPool.next_key(:baidu, keys_for(:baidu))
      end

      def sample_gaode_key
        KeyPool.next_key(:gaode, keys_for(:gaode))
      end

      def sample_tencent_key
        KeyPool.next_key(:tencent, keys_for(:tencent))
      end
    end
  end
end
