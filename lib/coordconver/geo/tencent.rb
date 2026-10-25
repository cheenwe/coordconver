# frozen_string_literal: true

module Coordconver
  module Geo
    # 腾讯位置服务 WebService API
    # 申请 key: https://lbs.qq.com/dev/console/application/mine (启用 WebServiceAPI)
    # 坐标为 GCJ-02; 逆地理编码 location 参数为 "lat,lng" 顺序
    module Tencent
      extend self

      # 视为"key 无效/配额超限"的状态码, 触发自动轮换下一个 key
      # 110 请求来源未被授权 112 IP未被授权 120 每秒调用量超限 121 日调用量超限 199 key结构错误
      KEY_ERROR_STATUSES = [110, 112, 120, 121, 199].freeze

      # 地理编码: 结构化地址 -> 坐标 (GCJ-02)
      # Coordconver::Tencent.geo("北京市海淀区彩和坊路海淀西大街74号")["result"]["location"]
      # 支持可选参数: region(城市), get_poi, ...
      def geo(address, options = {})
        params = { address: address }.merge(options)
        request("/geocoder/v1/", params)
      end

      # 逆地理编码: 坐标 (GCJ-02) -> 结构化地址
      # Coordconver::Tencent.regeo(116.322987, 39.983424)["result"]["address"]
      def regeo(lng, lat, options = {})
        params = {
          location: "#{lat},#{lng}", # 腾讯接口为 lat,lng 顺序
          get_poi: 0
        }.merge(options)
        request("/geocoder/v1/", params)
      end

      # IP 定位: IP -> 城市 + 坐标 (GCJ-02)
      def ip(ip = nil)
        params = {}
        params[:ip] = ip unless ip.nil? || ip.empty?
        request("/location/v1/ip", params)
      end

      # 便捷方法: 地址 -> [lng, lat] (GCJ-02), 解析失败返回 nil
      def geo_location(address, options = {})
        loc = geo(address, options).dig("result", "location")
        loc && [loc["lng"], loc["lat"]]
      end

      # 便捷方法: 坐标 -> 地址字符串 (GCJ-02), 解析失败返回 nil
      def regeo_address(lng, lat, options = {})
        result = regeo(lng, lat, options).dig("result") || {}
        result.dig("formatted_addresses", "recommend") || result["address"]
      end

      private

      def request(path, params)
        Api.call(
          provider: :tencent,
          url: base_url + path,
          params: params,
          key_param: :key,
          bad_result: ->(r) { KEY_ERROR_STATUSES.include?(r["status"].to_i) }
        )
      end

      def base_url
        Configuration.settings[:tencent_base_url].sub(%r{/\z}, "")
      end
    end
  end
end
