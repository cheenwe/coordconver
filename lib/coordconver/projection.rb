# frozen_string_literal: true

# 高斯-克吕格投影(横轴墨卡托)正反算, 以及 3°/6° 带号与中央经线换算。
# 适用于 CGCS2000 / 北京54 / 西安80 / WGS-84 椭球, 精度毫米级。
#
# 经 Coordconver.extend(Projection) 挂载:
#   Coordconver.gauss_kruger(121.47, 31.24)                      # => [x东坐标, y北坐标]
#   Coordconver.inverse_gauss_kruger(543_000, 3_456_000, central_meridian: 120)
#   Coordconver.zone_meridian(121.47, width: 3)                  # => [40, 120]
module Coordconver
  module Projection
    extend self

    # 椭球参数: a 长半轴(米), rf 扁率倒数
    ELLIPSOIDS = {
      cgcs2000: [6_378_137.0, 298.257_222_101],
      wgs84: [6_378_137.0, 298.257_223_563],
      krassovsky: [6_378_245.0, 298.3],       # 北京54
      iag75: [6_378_140.0, 298.257]           # 西安80
    }.freeze

    # 高斯-克吕格正算: 经纬度 -> 平面坐标 [东坐标 x, 北坐标 y] (米)
    # central_meridian: 中央经线(度), 缺省按 zone_width 自动推算
    # zone_width: 3 或 6 (度), 仅在未指定 central_meridian 时使用
    # false_easting: 东坐标偏移(米), 默认 500_000 (测绘惯例, 保证 x 为正)
    # ellipsoid: :cgcs2000 / :wgs84 / :krassovsky(北京54) / :iag75(西安80)
    def gauss_kruger(lng, lat, central_meridian: nil, zone_width: 6,
                     ellipsoid: :cgcs2000, false_easting: 500_000, false_northing: 0)
      a, f = ellipsoid_params(ellipsoid)
      cm = central_meridian || zone_meridian(lng, width: zone_width)[1]
      e2 = f * (2 - f)
      ep2 = e2 / (1 - e2)

      p = deg2rad(lat)
      dl = deg2rad(lng - cm)
      sin_p = Math.sin(p)
      cos_p = Math.cos(p)
      tan_p = Math.tan(p)

      n = a / Math.sqrt(1 - e2 * sin_p * sin_p)
      t = tan_p * tan_p
      c = ep2 * cos_p * cos_p
      aa = dl * cos_p
      m = meridional_arc(p, a, e2)

      x = false_easting + n * (aa +
            (1 - t + c) * aa**3 / 6 +
            (5 - 18 * t + t * t + 72 * c - 58 * ep2) * aa**5 / 120)
      y = false_northing + m + n * tan_p * (aa**2 / 2 +
            (5 - t + 9 * c + 4 * c * c) * aa**4 / 24 +
            (61 - 58 * t + t * t + 600 * c - 330 * ep2) * aa**6 / 720)
      [x.round(4), y.round(4)]
    end

    # 高斯-克吕格反算: 平面坐标 -> 经纬度 [lng, lat]
    # central_meridian 必填(反算无法从 x, y 推出投影带)
    def inverse_gauss_kruger(x, y, central_meridian:, ellipsoid: :cgcs2000,
                             false_easting: 500_000, false_northing: 0)
      a, f = ellipsoid_params(ellipsoid)
      e2 = f * (2 - f)
      ep2 = e2 / (1 - e2)

      m = y - false_northing
      mu = m / (a * (1 - e2 / 4 - 3 * e2**2 / 64 - 5 * e2**3 / 256))
      e1 = (1 - Math.sqrt(1 - e2)) / (1 + Math.sqrt(1 - e2))

      p1 = footpoint_latitude(mu, e1)
      sin_p1 = Math.sin(p1)
      cos_p1 = Math.cos(p1)
      tan_p1 = Math.tan(p1)

      c1 = ep2 * cos_p1 * cos_p1
      t1 = tan_p1 * tan_p1
      n1 = a / Math.sqrt(1 - e2 * sin_p1 * sin_p1)
      r1 = a * (1 - e2) / (1 - e2 * sin_p1 * sin_p1)**1.5
      d = (x - false_easting) / n1

      p = p1 - (n1 * tan_p1 / r1) * (d**2 / 2 -
            (5 + 3 * t1 + 10 * c1 - 4 * c1 * c1 - 9 * ep2) * d**4 / 24 +
            (61 + 90 * t1 + 298 * c1 + 45 * t1 * t1 - 252 * ep2 - 3 * c1 * c1) * d**6 / 720)
      l = (d -
            (1 + 2 * t1 + c1) * d**3 / 6 +
            (5 - 2 * c1 + 28 * t1 - 3 * c1 * c1 + 8 * ep2 + 24 * t1 * t1) * d**5 / 120) / cos_p1

      [rad2deg(l + deg2rad(central_meridian)), rad2deg(p)].map { |v| v.round(9) }
    end

    # 带号与中央经线: zone_meridian(121.47) => [21, 123], zone_meridian(121.47, width: 3) => [40, 120]
    def zone_meridian(lng, width: 6)
      raise ArgumentError, "带宽仅支持 3 或 6 度" unless [3, 6].include?(width)

      zone = width == 6 ? (lng / 6).floor + 1 : (lng / 3).round
      [zone, width == 6 ? zone * 6 - 3 : zone * 3]
    end

    private

    def ellipsoid_params(name)
      params = ELLIPSOIDS[name.to_s.downcase.to_sym]
      raise ArgumentError, "未知椭球: #{name.inspect} (支持 #{ELLIPSOIDS.keys.join(', ')})" unless params

      [params[0], 1.0 / params[1]]
    end

    # 子午线弧长
    def meridional_arc(p, a, e2)
      a * ((1 - e2 / 4 - 3 * e2**2 / 64 - 5 * e2**3 / 256) * p -
        (3 * e2 / 8 + 3 * e2**2 / 32 + 45 * e2**3 / 1024) * Math.sin(2 * p) +
        (15 * e2**2 / 256 + 45 * e2**3 / 1024) * Math.sin(4 * p) -
        (35 * e2**3 / 3072) * Math.sin(6 * p))
    end

    # 底点纬度迭代
    def footpoint_latitude(mu, e1)
      mu + (3 * e1 / 2 - 27 * e1**3 / 32) * Math.sin(2 * mu) +
        (21 * e1**2 / 16 - 55 * e1**4 / 32) * Math.sin(4 * mu) +
        (151 * e1**3 / 96) * Math.sin(6 * mu) +
        (1097 * e1**4 / 512) * Math.sin(8 * mu)
    end

    def deg2rad(deg)
      deg * Math::PI / 180.0
    end

    def rad2deg(rad)
      rad * 180.0 / Math::PI
    end
  end
end
