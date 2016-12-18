module Coordconver
  module Geo
    module Configuration

    extend self

      DEFAULT_BAIDU_MAP_OPTIONS = {
        api_version: 'v2',
        api_host: 'http://api.map.baidu.com/geocoder/',
        callback: 'renderReverse',
        output: 'json',
        pois: '1',
        valid_platform: ['android', 'ios']
      }


      attr_reader :settings

      def init(baidu_map_aks, gaode_map_keys)
        @settings = DEFAULT_BAIDU_MAP_OPTIONS.merge!(baidu_map_aks: baidu_map_aks, gaode_map_keys: gaode_map_keys)
      end
    end
  end
end



