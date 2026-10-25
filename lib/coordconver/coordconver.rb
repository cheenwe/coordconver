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
  # 平均地球半径(米), 球面距离/方位角计算使用
  EARTH_RADIUS = 6_371_008.8
  # 精确逆变换迭代次数
  PRECISE_ITERATIONS = 5
  # 中国区域大致边界。GCJ-02 加密仅在中国境内生效, 境外 WGS-84 与 GCJ-02 一致
  CHINA_LNG_RANGE = [72.004, 137.8347].freeze
  CHINA_LAT_RANGE = [0.8293, 55.8271].freeze

  # 轻量坐标点结构, 可直接传给转换方法:
  #   Coordconver.wgs_gcj(Coordconver.point(121.47, 31.25))
  Point = Struct.new(:lng, :lat, keyword_init: true) do
    def to_a
      [lng, lat]
    end

    def to_h
      { lng: lng, lat: lat }
    end
  end

  class << self
    # 构造 Point 结构
    def point(lng, lat)
      Point.new(lng: lng.to_f, lat: lat.to_f)
    end

    # 判断坐标是否在中国境外
    # Coordconver.out_of_china?(121.47, 31.25) # => false
    def out_of_china?(lng, lat)
      lng < CHINA_LNG_RANGE[0] || lng > CHINA_LNG_RANGE[1] ||
        lat < CHINA_LAT_RANGE[0] || lat > CHINA_LAT_RANGE[1]
    end

    # ---------- 坐标系转换 ----------
    # 所有方法支持三种入参: (lng, lat) 双参 / Point / [lng, lat] / {lng:, lat:}
    # 并支持 as: :hash 返回 {lng:, lat:}, as: :point 返回 Point, 默认 [lng, lat]

    # 百度坐标系 (BD-09) -> 火星坐标系 (GCJ-02)
    # 即 百度 -> 谷歌、高德、腾讯
    # Coordconver.bd_gcj(121.47981626441, 31.251161076123) # => [121.47328, 31.24522]
    def bd_gcj(lng, lat = nil, as: nil)
      a, b = extract_pair(lng, lat)
      x = a - 0.0065
      y = b - 0.006
      z = Math.sqrt(x * x + y * y) - 0.00002 * Math.sin(y * X_PI)
      theta = Math.atan2(y, x) - 0.000003 * Math.cos(x * X_PI)
      fmt([z * Math.cos(theta), z * Math.sin(theta)], as)
    end

    # 百度坐标系 (BD-09) -> 地球坐标 (WGS-84)
    # 即 百度 -> 地球坐标 (近似, 误差米级)
    def bd_wgs(lng, lat = nil, as: nil)
      a, b = extract_pair(lng, lat)
      fmt(gcj_wgs_raw(*bd_gcj_raw(a, b)), as)
    end

    # 百度坐标系 (BD-09) -> 地球坐标 (WGS-84), 迭代精确解, 厘米级
    def bd_wgs_precise(lng, lat = nil, as: nil)
      a, b = extract_pair(lng, lat)
      fmt(gcj_wgs_iterate(*bd_gcj_raw(a, b)), as)
    end

    # 火星坐标系 (GCJ-02) -> 地球坐标 (WGS-84)
    # 即 谷歌、高德、腾讯 -> 地球坐标。境外坐标原样返回。(近似, 误差米级)
    def gcj_wgs(lng, lat = nil, as: nil)
      a, b = extract_pair(lng, lat)
      fmt(gcj_wgs_raw(a, b), as)
    end

    # 火星坐标系 (GCJ-02) -> 地球坐标 (WGS-84), 迭代精确解, 厘米级
    # Coordconver.gcj_wgs_precise(*Coordconver.wgs_gcj(121.47, 31.24)) # => [121.47, 31.24]
    def gcj_wgs_precise(lng, lat = nil, as: nil)
      a, b = extract_pair(lng, lat)
      fmt(gcj_wgs_iterate(a, b), as)
    end

    # 火星坐标系 (GCJ-02) -> 百度坐标系 (BD-09)
    # 即 谷歌、高德、腾讯 -> 百度
    def gcj_bd(lng, lat = nil, as: nil)
      a, b = extract_pair(lng, lat)
      z = Math.sqrt(a * a + b * b) + 0.00002 * Math.sin(b * X_PI)
      theta = Math.atan2(b, a) + 0.000003 * Math.cos(a * X_PI)
      fmt([z * Math.cos(theta) + 0.0065, z * Math.sin(theta) + 0.006], as)
    end

    # 地球坐标 (WGS-84) -> 百度坐标系 (BD-09)
    # 即 地球坐标 -> 百度
    def wgs_bd(lng, lat = nil, as: nil)
      a, b = extract_pair(lng, lat)
      fmt(gcj_bd_raw(*wgs_gcj_raw(a, b)), as)
    end

    # 地球坐标 (WGS-84) -> 火星坐标系 (GCJ-02)
    # 即 地球坐标 -> 谷歌、高德、腾讯。境外坐标原样返回
    def wgs_gcj(lng, lat = nil, as: nil)
      a, b = extract_pair(lng, lat)
      fmt(wgs_gcj_raw(a, b), as)
    end

    # ---------- 批量转换 ----------
    # 支持数组/Point/Hash 混合输入:
    #   Coordconver.transform([[121.46, 31.24], {lng: 116.39, lat: 39.90}], from: :wgs84, to: :gcj02)
    # from/to 支持 :wgs84(wgs) :gcj02(gcj) :bd09(bd)
    def transform(points, from:, to:, as: nil)
      method = transform_method(from, to)
      points.map do |pt|
        a, b = extract_pair(pt)
        fmt(public_send(method, a, b), as)
      end
    end

    # ---------- 球面几何 ----------

    # 两点球面距离(Haversine 公式), 返回米。两点需在同一坐标系下。
    # Coordconver.distance(116.397428, 39.90923, 121.473701, 31.230416) # => 约 106.8 万米
    def distance(lng1, lat1, lng2, lat2)
      dlng = to_radian(lng2 - lng1)
      dlat = to_radian(lat2 - lat1)
      a = Math.sin(dlat / 2)**2 +
          Math.cos(to_radian(lat1)) * Math.cos(to_radian(lat2)) * Math.sin(dlng / 2)**2
      (2 * EARTH_RADIUS * Math.asin(Math.sqrt(a))).round(1)
    end

    # 起点到终点的初始方位角(以正北为 0°, 顺时针 0-360°)
    # Coordconver.bearing(116.397428, 39.90923, 121.473701, 31.230416) # => 约 137.5
    def bearing(lng1, lat1, lng2, lat2)
      p1 = to_radian(lat1)
      p2 = to_radian(lat2)
      dl = to_radian(lng2 - lng1)
      y = Math.sin(dl) * Math.cos(p2)
      x = Math.cos(p1) * Math.sin(p2) - Math.sin(p1) * Math.cos(p2) * Math.cos(dl)
      ((Math.atan2(y, x) * 180.0 / PI) + 360) % 360
    end

    # 从起点沿方位角移动指定距离(米)后的坐标
    # Coordconver.destination_point(116.397428, 39.90923, 137.5, 1_068_000)
    def destination_point(lng, lat, bearing_deg, distance_m, as: nil)
      d = distance_m.to_f / EARTH_RADIUS
      p1 = to_radian(lat)
      b = to_radian(bearing_deg)
      p2 = Math.asin(Math.sin(p1) * Math.cos(d) + Math.cos(p1) * Math.sin(d) * Math.cos(b))
      l2 = to_radian(lng) + Math.atan2(
        Math.sin(b) * Math.sin(d) * Math.cos(p1),
        Math.cos(d) - Math.sin(p1) * Math.sin(p2)
      )
      lon = ((l2 * 180.0 / PI) + 540) % 360 - 180
      fmt([lon, p2 * 180.0 / PI], as)
    end

    # ---------- 兼容旧式/语义化别名 ----------
    alias wgs84_gcj02 wgs_gcj
    alias gcj02_wgs84 gcj_wgs
    alias gcj02_bd09 gcj_bd
    alias bd09_gcj02 bd_gcj
    alias wgs84_bd09 wgs_bd
    alias bd09_wgs84 bd_wgs
    alias gcj02_wgs84_precise gcj_wgs_precise
    alias bd09_wgs84_precise bd_wgs_precise

    # 归一化坐标入参: 支持 (lng, lat) 双参 / Point / [lng, lat] / {lng:, lat:}
    def extract_pair(lng, lat = nil)
      return [lng.to_f, lat.to_f] unless lat.nil?

      case lng
      when Point then [lng.lng.to_f, lng.lat.to_f]
      when Hash
        [float_of(lng[:lng] || lng["lng"]), float_of(lng[:lat] || lng["lat"])]
      when Array then [float_of(lng[0]), float_of(lng[1])]
      else raise ArgumentError, "无法解析的坐标: #{lng.inspect} (支持 (lng, lat) / Point / [lng, lat] / {lng:, lat:})"
      end
    end

    private

    def float_of(v)
      raise ArgumentError, "坐标值无效: #{v.inspect}" if v.nil?

      Float(v)
    end

    def fmt(pair, as)
      case as
      when nil then pair
      when :hash then { lng: pair[0], lat: pair[1] }
      when :point then Point.new(lng: pair[0], lat: pair[1])
      else raise ArgumentError, "未知的返回格式: #{as.inspect} (支持 :hash / :point)"
      end
    end

    def transform_method(from, to)
      norm = ->(s) { s.to_s.downcase.gsub(/(84|02|09)\z/, "") }
      map = {
        %w[wgs gcj] => :wgs_gcj, %w[gcj wgs] => :gcj_wgs,
        %w[wgs bd] => :wgs_bd, %w[bd wgs] => :bd_wgs,
        %w[gcj bd] => :gcj_bd, %w[bd gcj] => :bd_gcj
      }
      m = map[[norm.call(from), norm.call(to)]]
      raise ArgumentError, "不支持的转换: #{from} -> #{to}" unless m

      m
    end

    def to_radian(deg)
      deg * PI / 180.0
    end

    # gcj_wgs 迭代精确解: 解方程 wgs_gcj(w) = g
    def gcj_wgs_iterate(lng, lat)
      w = [lng, lat]
      PRECISE_ITERATIONS.times do
        cur = wgs_gcj_raw(w[0], w[1])
        w = [w[0] + (lng - cur[0]), w[1] + (lat - cur[1])]
      end
      w
    end

    def gcj_wgs_raw(lng, lat)
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

    def wgs_gcj_raw(lng, lat)
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

    def gcj_bd_raw(lng, lat)
      z = Math.sqrt(lng * lng + lat * lat) + 0.00002 * Math.sin(lat * X_PI)
      theta = Math.atan2(lat, lng) + 0.000003 * Math.cos(lng * X_PI)
      [z * Math.cos(theta) + 0.0065, z * Math.sin(theta) + 0.006]
    end

    def bd_gcj_raw(lng, lat)
      x = lng - 0.0065
      y = lat - 0.006
      z = Math.sqrt(x * x + y * y) - 0.00002 * Math.sin(y * X_PI)
      theta = Math.atan2(y, x) - 0.000003 * Math.cos(x * X_PI)
      [z * Math.cos(theta), z * Math.sin(theta)]
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
