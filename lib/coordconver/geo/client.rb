module Coordconver
  module Geo
    class Client
      def initialize(baidu_map_aks, gaode_map_aks)
        Configuration.init(baidu_map_aks, gaode_map_aks)
      end
    end
  end
end

# Coordconver::Geo::Client.new