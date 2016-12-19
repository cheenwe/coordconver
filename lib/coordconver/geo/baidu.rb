module Coordconver
  module Geo
    module Baidu
      extend self

      # Coordconver::Baidu.regeo(39.983424,116.322987)
      def regeo(lng, lat)
        url = regeo_url(lng, lat)
        Utils::Request.get(url, params: nil)
      end


      def geo(address)
        url = base_url

        params = {
          ak: baidu_map_ak,
          output: 'json',
          address: address
        }

        Utils::Request.get(url, params: params)
      end

      private

      def regeo_url(lng, lat)
        base_url  + "?location=#{lat},#{lng}&output=json&ak=#{baidu_map_ak}"
      end

      # http://api.map.baidu.com/geocoder/v2/?location=39.983424,116.322987&output=json&ak=uzInpBxCpE0DiPnln3UbDv4OQTdOgmXu

      # http://api.map.baidu.com/geocoder/v2?location=39,116.480881&output=json&ak=uzInpBxCpE0DiPnln3UbDv4OQTdOgmXu

      # http://api.map.baidu.com/geocoder/v2/?output=json&address=百度大厦&city=北京市&ak=您的ak

      def base_url
        Configuration.settings[:baidu_base_url]
      end

      def baidu_map_ak
        Configuration.settings[:baidu_map_aks].sample
      end
    end
  end
end
