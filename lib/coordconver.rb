require "coordconver/version"
require "coordconver/coordconver"
require "coordconver/degree"
require "coordconver/geo/configuration"
require "coordconver/geo/client"
require "coordconver/geo/baidu"
require "coordconver/geo/gaode"
require "coordconver/utils/http"
require "coordconver/utils/request"

module Coordconver

  include Coordconver
  include Degree
  include Geo::Configuration
  include Geo
  include Utils

end
