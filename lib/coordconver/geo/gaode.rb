module Coordconver
  module Geo
    module Gaode
      extend self

      # Coordconver::Gaode.geocoding(116.480881,39.989410)
      # 116.480881,39.989410-->北京市朝阳区阜通东大街6号
      def geocoding(lng, lat)
        url = base_url(lng, lat)
        Utils::Request.get(url, params: nil)
      end


      # params = platform.nil? ? nil : { platform: build_platform(platform) }
      # url = base_url + alias_value
      # Utils::Request.get(url, params: params)

      private

      def base_url(lng, lat)
        "http://restapi.amap.com/v3/geocode/regeo?key=#{gaode_map_key}&location=#{lng},#{lat}"
      end

      def gaode_map_key
        Configuration.settings[:gaode_map_keys].sample
      end
    end
  end
end
