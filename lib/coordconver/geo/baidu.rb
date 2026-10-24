# frozen_string_literal: true

require "digest"

module Coordconver
  module Geo
    # 百度地图 Web 服务 API (Geocoding API v3)
    # 申请 key: https://lbsyun.baidu.com/apiconsole/key
    # 建议创建"服务端"类型 AK 并配置 IP 白名单; 若 AK 类型为"SN 校验", 需同时配置 baidu_sn
    module Baidu
      extend self

      # 地理编码: 结构化地址 -> 坐标
      # Coordconver::Baidu.geo("百度大厦")["result"]["location"] # => {"lng"=>116.30..., "lat"=>40.05...}
      # 支持可选参数: city(城市名), ret_coordtype(返回坐标类型, 默认 bd09ll)
      def geo(address, options = {})
        params = {
          address: address,
          output: "json",
          ak: baidu_map_ak
        }.merge(options)
        request("/geocoding/v3/", params)
      end

      # 逆地理编码: 坐标 -> 结构化地址
      # Coordconver::Baidu.regeo(116.322987, 39.983424)["result"]["formatted_address"]
      # options: coordtype(输入坐标类型, 默认 bd09ll, 可选 wgs84ll / gcj02ll 等)
      def regeo(lng, lat, options = {})
        params = {
          location: "#{lat},#{lng}",
          output: "json",
          ak: baidu_map_ak,
          coordtype: "bd09ll"
        }.merge(options)
        request("/reverse_geocoding/v3/", params)
      end

      # IP 定位: IP -> 城市 + 坐标 (BD-09)
      def ip(ip = nil)
        params = {
          ak: baidu_map_ak,
          coor: "bd09ll",
          output: "json"
        }
        params[:ip] = ip unless ip.nil? || ip.empty?
        request("/location/ip", params)
      end

      # 便捷方法: 地址 -> [lng, lat] (BD-09), 解析失败返回 nil
      def geo_location(address, options = {})
        resp = geo(address, options)
        loc = resp.dig("result", "location")
        loc && [loc["lng"], loc["lat"]]
      end

      # 便捷方法: 坐标 -> 地址字符串 (BD-09), 解析失败返回 nil
      def regeo_address(lng, lat, options = {})
        resp = regeo(lng, lat, options)
        resp.dig("result", "formatted_address")
      end

      private

      def request(path, params)
        url = base_url + path
        params = params.merge(sn: sn(path, params)) if sn_key
        Utils::Request.get(url, params: params)
      end

      def base_url
        Configuration.settings[:baidu_base_url].sub(%r{/\z}, "")
      end

      def baidu_map_ak
        Configuration.sample_baidu_ak
      end

      def sn_key
        Configuration.settings[:baidu_sn]
      end

      # SN 校验: sn = md5(urlencode(path + "?" + 按参数名字典序拼接的 query + sk))
      def sn(path, params)
        query = params.sort.map { |k, v| "#{k}=#{v}" }.join("&")
        Digest::MD5.hexdigest(custom_uri_encode("#{path}?#{query}") + sn_key)
      end

      # 百度 SN 校验要求的 URI 编码: 仅 A-Za-z0-9-_.~ 不编码, 其余按字节转 %XX 大写
      def custom_uri_encode(str)
        str.gsub(/[^A-Za-z0-9\-_.~]/) do |char|
          char.bytes.map { |b| format("%%%02X", b) }.join
        end
      end
    end
  end
end
