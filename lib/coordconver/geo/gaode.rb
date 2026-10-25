# frozen_string_literal: true

module Coordconver
  module Geo
    # 高德地图 Web 服务 API
    # 申请 key: https://console.amap.com/dev/key/app (类型选"Web服务")
    module Gaode
      extend self

      # 视为"key 无效/配额超限"的 infocode, 触发自动轮换下一个 key
      # 10001 KEY不合法 10003 日调用量超限 10009 KEY类型错误 10044 超出支持范围 20003 日调用量超限
      KEY_ERROR_INFOCODES = %w[10001 10003 10009 10044 20003].freeze

      # 高德官方坐标转换接口支持的源坐标系
      COORDSYS_MAP = {
        gps: "gps", wgs84: "gps", wgs: "gps",
        baidu: "baidu", bd09: "baidu", bd: "baidu",
        gcj02: "autonavi", gcj: "autonavi", autonavi: "autonavi"
      }.freeze

      # 地理编码: 结构化地址 -> 坐标 (GCJ-02)
      # Coordconver::Gaode.geo("北京方恒国际中心A座")["geocodes"][0]["location"] # => "116.480724,39.989584"
      # 支持可选参数: city(城市名), citylimit, batch, ...
      def geo(address, options = {})
        params = { address: address }.merge(options)
        request("/geocode/geo", params)
      end

      # 逆地理编码: 坐标 (GCJ-02) -> 结构化地址
      # Coordconver::Gaode.regeo(116.480881, 39.989410)["regeocode"]["formatted_address"]
      # options: extensions(base/all), radius, poitype, ...
      def regeo(lng, lat, options = {})
        params = { location: "#{lng},#{lat}" }.merge(options)
        request("/geocode/regeo", params)
      end

      # 官方坐标转换 API: 将 GPS(WGS-84)/百度(BD-09) 坐标转换为高德坐标 (GCJ-02)。
      # 与离线算法互为补充, 适合需要官方权威转换结果的场景。
      # 单点或数组均可(最多 40 个点):
      #   Coordconver::Gaode.convert([121.468738, 31.247138], from: :gps)
      #   Coordconver::Gaode.convert([[121.46, 31.24], [116.39, 39.90]], from: :gps)
      # 返回完整 JSON; from 支持 :gps(wgs84) / :baidu(bd09) / :gcj02
      def convert(points, from: :gps)
        coordsys = COORDSYS_MAP[from.to_s.downcase.to_sym]
        raise ArgumentError, "不支持的源坐标系: #{from.inspect} (支持 :gps/:wgs84, :baidu/:bd09, :gcj02)" unless coordsys

        list = normalize_point_list(points)
        raise ArgumentError, "单次最多转换 40 个坐标点" if list.size > 40

        params = {
          locations: list.map { |pt| Coordconver.extract_pair(pt).join(",") }.join(";"),
          coordsys: coordsys
        }
        request("/assistant/coordinate/convert", params)
      end

      # convert 的便捷版本, 返回 [[lng, lat], ...] (GCJ-02), 失败返回 nil
      def convert_location(points, from: :gps)
        resp = convert(points, from: from)
        return nil unless resp["status"] == "1" && resp["locations"]

        resp["locations"].split(";").map { |s| s.split(",").map(&:to_f) }
      end

      # 便捷方法: 地址 -> [lng, lat] (GCJ-02), 解析失败返回 nil
      def geo_location(address, options = {})
        resp = geo(address, options)
        geocode = resp["geocodes"] && resp["geocodes"][0]
        loc = geocode && geocode["location"]
        return nil if loc.nil? || loc.empty?

        loc.split(",").map(&:to_f)
      end

      # 便捷方法: 坐标 -> 地址字符串 (GCJ-02), 解析失败返回 nil
      def regeo_address(lng, lat, options = {})
        regeo(lng, lat, options).dig("regeocode", "formatted_address")
      end

      private

      def normalize_point_list(points)
        list = points.is_a?(Array) && points.first.is_a?(Numeric) ? [points] : Array(points)
        raise ArgumentError, "未提供坐标点" if list.empty?

        list
      end

      def request(path, params)
        Api.call(
          provider: :gaode,
          url: base_url + path,
          params: params,
          key_param: :key,
          bad_result: ->(r) { r["status"].to_s == "0" && KEY_ERROR_INFOCODES.include?(r["infocode"].to_s) }
        )
      end

      def base_url
        # 兼容旧版本以 /geocode 结尾的 base_url 配置
        Configuration.settings[:gaode_base_url].sub(%r{/geocode/?\z}, "").sub(%r{/\z}, "")
      end
    end
  end
end
