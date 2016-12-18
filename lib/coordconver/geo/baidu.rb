module Coordconver
  module Geo
    module Baidu
      extend self

      # Coordconver::Baidu.geocoding(39.983424,116.322987)
      def geocoding(lng, lat)
        url = base_url(lng, lat)
        Utils::Request.get(url, params: nil)
      end

      # params = platform.nil? ? nil : { platform: build_platform(platform) }
      # url = base_url + alias_value
      # Utils::Request.get(url, params: params)

      private

      def base_url(lng, lat)
        "http://api.map.baidu.com/geocoder/v2/?location=#{lng},#{lat}&output=json&pois=1&ak=#{baidu_map_ak}"
      end

      def baidu_map_ak
        Configuration.settings[:baidu_map_aks].sample
      end
    end
  end
end
