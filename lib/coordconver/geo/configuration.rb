module Coordconver
  module Geo
    module Configuration
      extend self

      DEFAULT_MAP_OPTIONS = {
        gaode_base_url: 'http://restapi.amap.com/v3/geocode',
        baidu_base_url: 'http://api.map.baidu.com/geocoder/v2/',
        output: 'json'
      }

      attr_reader :settings

      def init(baidu_map_aks, gaode_map_keys)
        @settings = DEFAULT_MAP_OPTIONS.merge!(baidu_map_aks: baidu_map_aks, gaode_map_keys: gaode_map_keys)
      end
    end
  end
end



