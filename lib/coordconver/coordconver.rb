# frozen_string_literal: true

# 坐标系互转核心算法(纯离线计算)。
#
# BD-09   百度坐标系, 百度地图使用
# GCJ-02  火星坐标系(国测局), 高德/腾讯/谷歌中国使用
# WGS-84  地球坐标系, GPS 设备原始坐标
module Coordconver
  X_PI = 3.14159265358979324 * 3000.0 / 180.0
  PI = 3.1415926535897932384626
  # 克拉索夫斯基椭球参数(GCJ-02 偏移算法使用)
  SEMI_MAJOR_AXIS = 6378245.0
  ECCENTRICITY_SQUARED = 0.00669342162296594323
  # 平均地球半径(米), 球面距离计算使用
  EARTH_RADIUS = 6_371_008.8
  # 中国区域大致边界。GCJ-02 加密仅在中国境内生效, 境外 WGS-84 与 GCJ-02 一致
  CHINA_LNG_RANGE = [72.004, 137.8347].freeze
  CHINA_LAT_RANGE = [0.8293, 55.8271].freeze

  class << self
    # 判断坐标是否在中国境外
    # Coordconver.out_of_china?(121.47, 31.25) # => false
    def out_of_china?(lng, lat)
      lng < CHINA_LNG_RANGE[0] || lng > CHINA_LNG_RANGE[1] ||
        lat < CHINA_LAT_RANGE[0] || lat > CHINA_LAT_RANGE[1]
    end

    # 百度坐标系 (BD-09) -> 火星坐标系 (GCJ-02)
    # 即 百度 -> 谷歌、高德
    # Coordconver.bd_gcj(121.47981626441, 31.251161076123) # => [121.47328, 31.24522]
    def bd_gcj(lng, lat)
      x = lng - 0.0065
      y = lat - 0.006
      z = Math.sqrt(x * x + y * y) - 0.00002 * Math.sin(y * X_PI)
      theta = Math.atan2(y, x) - 0.000003 * Math.cos(x * X_PI)
      [z * Math.cos(theta), z * Math.sin(theta)]
    end

    # 百度坐标系 (BD-09) -> 地球坐标 (WGS-84)
    # 即 百度 -> 地球坐标
    def bd_wgs(lng, lat)
      gcj_wgs(*bd_gcj(lng, lat))
    end

    # 火星坐标系 (GCJ-02) -> 地球坐标 (WGS-84)
    # 即 谷歌、高德 -> 地球坐标。境外坐标原样返回
    def gcj_wgs(lng, lat)
      return [lng, lat] if out_of_china?(lng, lat)

      dlat = transformlat(lng - 105.0, lat - 35.0)
      dlng = transformlng(lng - 105.0, lat - 35.0)
      radlat = lat / 180.0 * PI
      magic = 1 - ECCENTRICITY_SQUARED * Math.sin(radlat) * Math.sin(radlat)
      sqrtmagic = Math.sqrt(magic)
      dlat = (dlat * 180.0) / ((SEMI_MAJOR_AXIS * (1 - ECCENTRICITY_SQUARED)) / (magic * sqrtmagic) * PI)
      dlng = (dlng * 180.0) / (SEMI_MAJOR_AXIS / sqrtmagic * Math.cos(radlat) * PI)
      mglat = lat + dlat
      mglng = lng + dlng
      [lng * 2 - mglng, lat * 2 - mglat]
    end

    # 火星坐标系 (GCJ-02) -> 百度坐标系 (BD-09)
    # 即 谷歌、高德 -> 百度
    def gcj_bd(lng, lat)
      z = Math.sqrt(lng * lng + lat * lat) + 0.00002 * Math.sin(lat * X_PI)
      theta = Math.atan2(lat, lng) + 0.000003 * Math.cos(lng * X_PI)
      [z * Math.cos(theta) + 0.0065, z * Math.sin(theta) + 0.006]
    end

    # 地球坐标 (WGS-84) -> 百度坐标系 (BD-09)
    # 即 地球坐标 -> 百度
    def wgs_bd(lng, lat)
      gcj_bd(*wgs_gcj(lng, lat))
    end

    # 地球坐标 (WGS-84) -> 火星坐标系 (GCJ-02)
    # 即 地球坐标 -> 谷歌、高德。境外坐标原样返回
    def wgs_gcj(lng, lat)
      return [lng, lat] if out_of_china?(lng, lat)

      dlat = transformlat(lng - 105.0, lat - 35.0)
      dlng = transformlng(lng - 105.0, lat - 35.0)
      radlat = lat / 180.0 * PI
      magic = 1 - ECCENTRICITY_SQUARED * Math.sin(radlat) * Math.sin(radlat)
      sqrtmagic = Math.sqrt(magic)
      dlat = (dlat * 180.0) / ((SEMI_MAJOR_AXIS * (1 - ECCENTRICITY_SQUARED)) / (magic * sqrtmagic) * PI)
      dlng = (dlng * 180.0) / (SEMI_MAJOR_AXIS / sqrtmagic * Math.cos(radlat) * PI)
      [lng + dlng, lat + dlat]
    end

    # 两点球面距离(Haversine 公式), 返回米。
    # 两点需在同一坐标系下。结果四舍五入到 0.1 米。
    # Coordconver.distance(116.397428, 39.90923, 121.473701, 31.230416) # => 约 106.8 万米
    def distance(lng1, lat1, lng2, lat2)
      dlng = to_radian(lng2 - lng1)
      dlat = to_radian(lat2 - lat1)
      a = Math.sin(dlat / 2)**2 +
          Math.cos(to_radian(lat1)) * Math.cos(to_radian(lat2)) * Math.sin(dlng / 2)**2
      (2 * EARTH_RADIUS * Math.asin(Math.sqrt(a))).round(1)
    end

    # 语义化别名
    alias wgs84_gcj02 wgs_gcj
    alias gcj02_wgs84 gcj_wgs
    alias gcj02_bd09 gcj_bd
    alias bd09_gcj02 bd_gcj
    alias wgs84_bd09 wgs_bd
    alias bd09_wgs84 bd_wgs

    private

    def to_radian(deg)
      deg * PI / 180.0
    end

    def transformlat(lng, lat)
      ret = -100.0 + 2.0 * lng + 3.0 * lat + 0.2 * lat * lat + 0.1 * lng * lat + 0.2 * Math.sqrt(lng.abs)
      ret += (20.0 * Math.sin(6.0 * lng * PI) + 20.0 * Math.sin(2.0 * lng * PI)) * 2.0 / 3.0
      ret += (20.0 * Math.sin(lat * PI) + 40.0 * Math.sin(lat / 3.0 * PI)) * 2.0 / 3.0
      ret += (160.0 * Math.sin(lat / 12.0 * PI) + 320 * Math.sin(lat * PI / 30.0)) * 2.0 / 3.0
      ret
    end

    def transformlng(lng, lat)
      ret = 300.0 + lng + 2.0 * lat + 0.1 * lng * lng + 0.1 * lng * lat + 0.1 * Math.sqrt(lng.abs)
      ret += (20.0 * Math.sin(6.0 * lng * PI) + 20.0 * Math.sin(2.0 * lng * PI)) * 2.0 / 3.0
      ret += (20.0 * Math.sin(lng * PI) + 40.0 * Math.sin(lng / 3.0 * PI)) * 2.0 / 3.0
      ret += (150.0 * Math.sin(lng / 12.0 * PI) + 300.0 * Math.sin(lng / 30.0 * PI)) * 2.0 / 3.0
      ret
    end
  end
end
