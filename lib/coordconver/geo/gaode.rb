module Coordconver
  module Geo
    module Gaode
      extend self

      # Coordconver::Gaode.regeo(116.480881,39.989410)
      # 116.480881,39.989410-->北京市朝阳区阜通东大街6号
      def regeo(lng, lat)
        url = regeo_url(lng, lat)
        # params = {
        #   key: gaode_map_key,
        #   location: lng + "," + lat
        # }

        Utils::Request.get(url, params: nil)
      end

      # Coordconver::Gaode.geo("北京市朝阳区阜通东大街6号")
      # 116.480881,39.989410-->北京市朝阳区阜通东大街6号
      def geo(address)
        url = geo_url

        params = {
          key: gaode_map_key,
          address: address
        }

        Utils::Request.get(url, params: params)
      end

      private

      def regeo_url(lng, lat)
        base_url + '/regeo' + "?key=#{gaode_map_key}&location=#{lng},#{lat}"
      end

      def geo_url
        base_url + '/geo'
      end

      def base_url
        Configuration.settings[:gaode_base_url]
      end

      def gaode_map_key
        Configuration.settings[:gaode_map_keys].sample
      end
    end
  end
end
