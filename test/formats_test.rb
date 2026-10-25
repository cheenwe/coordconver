require 'test_helper'

class FormatsTest < Minitest::Test
  def test_parse_wkt
    assert_equal [121.47, 31.25], Coordconver.parse_wkt("POINT (121.47 31.25)")
    assert_equal [121.47, 31.25], Coordconver.parse_wkt("POINT(121.47 31.25)")
    assert_equal [-121.47, 31.25], Coordconver.parse_wkt("point (-121.47 31.25)")
  end

  def test_parse_wkt_invalid
    assert_raises(ArgumentError) { Coordconver.parse_wkt("LINESTRING (0 0, 1 1)") }
    assert_raises(ArgumentError) { Coordconver.parse_wkt("随便一段话") }
  end

  def test_to_wkt
    assert_equal "POINT (121.47 31.25)", Coordconver.to_wkt(121.47, 31.25)
  end

  def test_wkt_round_trip
    wkt = "POINT (121.468738 31.247138)"
    lng, lat = Coordconver.parse_wkt(wkt)
    assert_equal "POINT (121.468738 31.247138)", Coordconver.to_wkt(lng, lat)
  end

  def test_parse_geojson_hash
    input = { "type" => "Point", "coordinates" => [121.47, 31.25] }
    assert_equal [121.47, 31.25], Coordconver.parse_geojson(input)
  end

  def test_parse_geojson_string
    assert_equal [121.47, 31.25],
      Coordconver.parse_geojson('{"type":"Point","coordinates":[121.47,31.25]}')
  end

  def test_parse_geojson_feature
    input = {
      "type" => "Feature",
      "geometry" => { "type" => "Point", "coordinates" => [121.47, 31.25] },
      "properties" => {}
    }
    assert_equal [121.47, 31.25], Coordconver.parse_geojson(input)
  end

  def test_parse_geojson_invalid
    assert_raises(ArgumentError) { Coordconver.parse_geojson({ "type" => "LineString", "coordinates" => [] }) }
    assert_raises(ArgumentError) { Coordconver.parse_geojson({ "type" => "Point" }) }
    assert_raises(JSON::ParserError) { Coordconver.parse_geojson("不是JSON") }
  end

  def test_to_geojson
    assert_equal({ "type" => "Point", "coordinates" => [121.47, 31.25] },
      Coordconver.to_geojson(121.47, 31.25))
    assert_equal '{"type":"Point","coordinates":[121.47,31.25]}',
      Coordconver.to_geojson_string(121.47, 31.25)
  end

  def test_geojson_to_geojson_round_trip
    lng, lat = Coordconver.parse_geojson(Coordconver.to_geojson(116.481499, 39.990475))
    assert_equal [116.481499, 39.990475], [lng, lat]
  end

  # 与坐标系转换组合使用
  def test_convert_geojson_point
    geojson = { "type" => "Point", "coordinates" => [121.468738, 31.247138] }
    converted = Coordconver.wgs_gcj(Coordconver.parse_geojson(geojson), as: :point)
    assert_instance_of Coordconver::Point, converted
    assert_in_delta 121.473278, converted.lng, 0.0001
  end
end
