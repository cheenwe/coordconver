# frozen_string_literal: true

# 经纬度(十进制度)与度分秒(DMS)互转。
#
# 经 Coordconver.extend(Degree) 挂载, 以下两种写法等价:
#   Coordconver.degree(38.65777, 104.08296)
#   Coordconver::Degree.degree(38.65777, 104.08296)
module Coordconver
  module Degree
    extend self

    # 坐标转度分秒, 返回 [经度, 纬度] 的 DMS 字符串。
    # 负值按西经/南纬处理, 取绝对值后再格式化。
    # Coordconver.degree(38.65777, 104.08296) # => ["38°39′27.97″", "104°4′58.66″"]
    def degree(lng, lat)
      [cal_degree(lng), cal_degree(lat)]
    end

    # 单个十进制度数转度分秒字符串, 默认保留两位小数秒。
    # Coordconver.cal_degree(38.65777)    # => "38°39′27.97″"
    # Coordconver.cal_degree(38.65777, 0) # => "38°39′27″"
    def cal_degree(n, precision = 2)
      sign = n.negative? ? "-" : ""
      n = n.abs
      d = n.to_i
      m = (n - d) * 60
      s = (m - m.to_i) * 60
      if precision.zero?
        "#{sign}#{d}°#{m.to_i}′#{s.round}″"
      else
        "#{sign}#{d}°#{m.to_i}′#{s.round(precision)}″"
      end
    end

    # 度分秒转坐标, 返回 [经度, 纬度] 浮点值。
    # 兼容 "38°39′27.97″"、"38°39′27.97""、"38d39m27.97s"、"38:39:27.97" 等写法。
    # Coordconver.undegree("38°39′27.97″", "104°4′58.66″") # => [38.65777, 104.08296]
    def undegree(lng, lat)
      [cal_undegree(lng), cal_undegree(lat)]
    end

    # 单个度分秒字符串转十进制度数。
    # Coordconver.cal_undegree("104°4′58.66″") # => 104.08296
    # Coordconver.cal_undegree("-38°39′27.97″") # => -38.65777
    def cal_undegree(str)
      parts = str.to_s.scan(/[-+]?\d+(?:\.\d+)?/)
      return 0.0 if parts.empty?

      deg, min, sec = parts.map(&:to_f)
      min ||= 0.0
      sec ||= 0.0
      value = deg.abs + min / 60.0 + sec / 3600.0
      value = -value if str.to_s =~ /^\s*[-–]/ || deg.negative?
      value.round(6)
    end
  end
end
