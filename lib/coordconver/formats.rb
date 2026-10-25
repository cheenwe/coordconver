# frozen_string_literal: true

require "json"

# WKT / GeoJSON 与坐标互转。
# 经 Coordconver.extend(Formats) 挂载:
#   Coordconver.parse_wkt("POINT (121.47 31.25)")    # => [121.47, 31.25]
#   Coordconver.to_wkt(121.47, 31.25)                # => "POINT (121.47 31.25)"
#   Coordconver.to_geojson(121.47, 31.25)            # => {"type"=>"Point", "coordinates"=>[121.47, 31.25]}
module Coordconver
  module Formats
    extend self

    # 解析 WKT 点: "POINT (121.47 31.25)" / "POINT(121.47 31.25)" -> [lng, lat]
    def parse_wkt(wkt)
      match = wkt.to_s.match(/point\s*z?m?\s*\(\s*([+-]?\d+(?:\.\d+)?)\s+([+-]?\d+(?:\.\d+)?)/i)
      raise ArgumentError, "无法解析 WKT: #{wkt.inspect} (仅支持 POINT)" unless match

      [match[1].to_f, match[2].to_f]
    end

    # 生成 WKT 点
    def to_wkt(lng, lat)
      "POINT (#{lng} #{lat})"
    end

    # 解析 GeoJSON: 接受 Hash 或 JSON 字符串。
    # 支持 Point 与包着 Point 的 Feature。
    # 返回 [lng, lat]
    def parse_geojson(input)
      obj = input.is_a?(Hash) ? input : JSON.parse(input.to_s)
      obj = obj["geometry"] if obj["type"] == "Feature"
      raise ArgumentError, "仅支持 GeoJSON Point, 实际: #{obj['type'].inspect}" unless obj["type"] == "Point"

      coords = obj["coordinates"]
      raise ArgumentError, "GeoJSON Point 缺少 coordinates" unless coords.is_a?(Array) && coords.size >= 2

      [coords[0].to_f, coords[1].to_f]
    end

    # 生成 GeoJSON Point Hash (GeoJSON 规范中坐标为 [lng, lat] 顺序)
    def to_geojson(lng, lat)
      { "type" => "Point", "coordinates" => [lng, lat] }
    end

    # 生成 GeoJSON Point JSON 字符串
    def to_geojson_string(lng, lat)
      JSON.generate(to_geojson(lng, lat))
    end
  end
end
