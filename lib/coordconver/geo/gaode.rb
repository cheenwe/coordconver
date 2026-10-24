# frozen_string_literal: true

module Coordconver
  module Geo
    # 高德地图 Web 服务 API
    # 申请 key: https://console.amap.com/dev/key/app (类型选"Web服务")
    module Gaode
      extend self

      # 地理编码: 结构化地址 -> 坐标 (GCJ-02)
      # Coordconver::Gaode.geo("北京方恒国际中心A座")["geocodes"][0]["location"] # => "116.480724,39.989584"
      # 支持可选参数: city(城市名), citylimit, batch, ...
      def geo(address, options = {})
        params = {
          key: gaode_map_key,
          address: address
        }.merge(options)
        request("/geocode/geo", params)
      end

      # 逆地理编码: 坐标 (GCJ-02) -> 结构化地址
      # Coordconver::Gaode.regeo(116.480881, 39.989410)["regeocode"]["formatted_address"]
      # options: extensions(base/all), radius, poitype, ...
      def regeo(lng, lat, options = {})
        params = {
          key: gaode_map_key,
          location: "#{lng},#{lat}"
        }.merge(options)
        request("/geocode/regeo", params)
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
        resp = regeo(lng, lat, options)
        resp.dig("regeocode", "formatted_address")
      end

      private

      def request(path, params)
        Utils::Request.get(base_url + path, params: params)
      end

      def base_url
        # 兼容旧版本以 /geocode 结尾的 base_url 配置
        Configuration.settings[:gaode_base_url].sub(%r{/geocode/?\z}, "").sub(%r{/\z}, "")
      end

      def gaode_map_key
        Configuration.sample_gaode_key
      end
    end
  end
end
