require 'test_helper'

class CoordconverTest < Minitest::Test
  # 参考点 (来源: gpsspg.com / 百度与高德官方转换示例):
  #   WGS-84: 121.468738, 31.247138   上海市静安区海宁路
  #   GCJ-02: 121.473279, 31.245217
  #   BD-09:  121.479816, 31.251161

  def test_out_of_china
    assert Coordconver.out_of_china?(121.47, 31.25) == false
    assert Coordconver.out_of_china?(-0.13, 51.5) == true
    assert Coordconver.out_of_china?(139.7, 35.7) == true
  end

  def test_wgs_gcj
    assert_equal [116.4876, 39.9918],
      Coordconver.wgs_gcj(116.481499, 39.990475).map { |a| a.round(4) }
  end

  def test_wgs_gcj_precision
    assert_equal [116.487586, 39.991654],
      Coordconver.wgs_gcj(116.481499, 39.990375).map { |a| a.round(6) }
  end

  def test_wgs_gcj_out_of_china_passthrough
    assert_equal [-0.13, 51.5], Coordconver.wgs_gcj(-0.13, 51.5)
  end

  def test_gcj_wgs
    assert_equal [121.469, 31.247],
      Coordconver.gcj_wgs(121.473279, 31.245217).map { |a| a.round(3) }
  end

  def test_gcj_wgs_out_of_china_passthrough
    assert_equal [-0.13, 51.5], Coordconver.gcj_wgs(-0.13, 51.5)
  end

  def test_bd_gcj
    assert_equal [116.47490, 39.98472],
      Coordconver.bd_gcj(116.481499, 39.990475).map { |a| a.round(5) }
  end

  def test_gcj_bd
    assert_equal [121.4798, 31.2512],
      Coordconver.gcj_bd(121.473279, 31.245217).map { |a| a.round(4) }
  end

  def test_wgs_bd
    assert_equal [121.4798, 31.2512],
      Coordconver.wgs_bd(121.46873833333332, 31.247138333333336).map { |a| a.round(4) }
  end

  # 回归测试: 修复前 bd_wgs 错误地复用了 wgs_bd 的逻辑, 结果方向反了
  def test_bd_wgs
    assert_equal [121.469, 31.247],
      Coordconver.bd_wgs(121.47981626441, 31.251161076123).map { |a| a.round(3) }
  end

  def test_aliases
    assert_equal Coordconver.wgs_gcj(116.481499, 39.990475),
      Coordconver.wgs84_gcj02(116.481499, 39.990475)
    assert_equal Coordconver.bd_wgs(121.47981626441, 31.251161076123),
      Coordconver.bd09_wgs84(121.47981626441, 31.251161076123)
    assert_equal Coordconver.wgs_bd(121.468738, 31.247138),
      Coordconver.wgs84_bd09(121.468738, 31.247138)
  end

  # gcj_wgs 为近似逆运算, 往返误差在米级 (~1e-5°) 属正常
  def test_round_trip_wgs_bd_wgs
    original = [121.468738, 31.247138]
    back = Coordconver.bd_wgs(*Coordconver.wgs_bd(*original))
    assert_in_delta original[0], back[0], 0.00005
    assert_in_delta original[1], back[1], 0.00005
  end

  def test_distance_zero
    assert_equal 0.0, Coordconver.distance(116.4, 39.9, 116.4, 39.9)
  end

  # 北京天安门 -> 上海人民广场, 实际约 1068 km
  def test_distance_beijing_to_shanghai
    assert_in_delta 1_068_203, Coordconver.distance(116.397428, 39.90923, 121.473701, 31.230416), 100
  end

  def test_distance_symmetry
    d1 = Coordconver.distance(116.397, 39.909, 121.473, 31.230)
    d2 = Coordconver.distance(121.473, 31.230, 116.397, 39.909)
    assert_equal d1, d2
  end

  # ---------- 方位角与偏移点 ----------

  def test_bearing_cardinal_directions
    assert_in_delta 0, Coordconver.bearing(0, 0, 0, 1), 0.001       # 正北
    assert_in_delta 90, Coordconver.bearing(0, 0, 1, 0), 0.001      # 正东
    assert_in_delta 180, Coordconver.bearing(0, 1, 0, 0), 0.001     # 正南
    assert_in_delta 270, Coordconver.bearing(1, 0, 0, 0), 0.001     # 正西
  end

  # 北京 -> 上海 初始方位角约 153° (东南偏南)
  def test_bearing_beijing_to_shanghai
    assert_in_delta 153.04, Coordconver.bearing(116.397428, 39.90923, 121.473701, 31.230416), 0.5
  end

  # 赤道上沿正东走四分之一赤道周长, 应到经度 90°
  def test_destination_point_quarter_equator
    quarter = Math::PI * Coordconver::EARTH_RADIUS / 2
    lng, lat = Coordconver.destination_point(0, 0, 90, quarter)
    assert_in_delta 90, lng, 1e-6
    assert_in_delta 0, lat, 1e-6
  end

  def test_destination_point_round_trip
    origin = [116.397428, 39.90923]
    dest = Coordconver.destination_point(*origin, 153.0, 100_000)
    traveled = Coordconver.distance(*origin, *dest)
    assert_in_delta 100_000, traveled, traveled * 0.001
  end

  def test_destination_point_as_hash
    result = Coordconver.destination_point(0, 0, 90, 1000, as: :hash)
    assert_instance_of Hash, result
    assert_in_delta 0.009, result[:lng], 0.001
  end

  # ---------- 入参格式与返回格式 ----------

  def test_point_struct
    p = Coordconver.point(121.468738, 31.247138)
    assert_instance_of Coordconver::Point, p
    assert_equal 121.468738, p.lng
    assert_equal [121.468738, 31.247138], p.to_a
    assert_equal({ lng: 121.468738, lat: 31.247138 }, p.to_h)
  end

  def test_conversion_accepts_point_input
    result = Coordconver.wgs_gcj(Coordconver.point(121.468738, 31.247138))
    assert_equal Coordconver.wgs_gcj(121.468738, 31.247138), result
  end

  def test_conversion_accepts_array_and_hash_input
    assert_equal Coordconver.wgs_gcj(121.468738, 31.247138), Coordconver.wgs_gcj([121.468738, 31.247138])
    assert_equal Coordconver.wgs_gcj(121.468738, 31.247138), Coordconver.wgs_gcj({ lng: 121.468738, lat: 31.247138 })
    assert_equal Coordconver.wgs_gcj(121.468738, 31.247138), Coordconver.wgs_gcj({ "lng" => 121.468738, "lat" => 31.247138 })
  end

  def test_conversion_as_hash
    result = Coordconver.wgs_gcj(121.468738, 31.247138, as: :hash)
    assert_equal({ lng: 121.47327833883615, lat: 31.2452165865549 }, result)
  end

  def test_conversion_as_point
    result = Coordconver.gcj_bd(121.473279, 31.245217, as: :point)
    assert_instance_of Coordconver::Point, result
    assert_in_delta 121.4798, result.lng, 0.0001
  end

  def test_conversion_invalid_as
    assert_raises(ArgumentError) { Coordconver.wgs_gcj(121.47, 31.24, as: :xml) }
  end

  # ---------- 批量转换 ----------

  def test_transform_arrays
    from = [[121.468738, 31.247138], [116.481499, 39.990475]]
    expected = from.map { |lng, lat| Coordconver.wgs_gcj(lng, lat) }
    assert_equal expected, Coordconver.transform(from, from: :wgs84, to: :gcj02)
  end

  def test_transform_mixed_input
    mixed = [[121.468738, 31.247138], Coordconver.point(116.481499, 39.990475), { lng: 104.08, lat: 30.65 }]
    result = Coordconver.transform(mixed, from: "WGS84", to: "BD09", as: :hash)
    assert_equal 3, result.size
    assert_instance_of Hash, result[0]
    assert_equal Coordconver.wgs_bd(104.08, 30.65, as: :hash), result[2]
  end

  def test_transform_invalid_direction
    assert_raises(ArgumentError) { Coordconver.transform([[121, 31]], from: :wgs84, to: :bd9999) }
  end

  # ---------- 精确逆变换 ----------

  def test_gcj_wgs_precise_round_trip
    original = [121.468738, 31.247138]
    back = Coordconver.gcj_wgs_precise(*Coordconver.wgs_gcj(*original))
    assert_in_delta original[0], back[0], 1e-7, "精确逆变换经度误差应 < 1e-7 度"
    assert_in_delta original[1], back[1], 1e-7, "精确逆变换纬度误差应 < 1e-7 度"
  end

  def test_precise_more_accurate_than_approximate
    original = [121.468738, 31.247138]
    g = Coordconver.wgs_gcj(*original)
    approx = Coordconver.gcj_wgs(*g)
    precise = Coordconver.gcj_wgs_precise(*g)
    assert_operator (approx[0] - original[0]).abs, :>, (precise[0] - original[0]).abs
    assert_operator (approx[1] - original[1]).abs, :>, (precise[1] - original[1]).abs
  end

  def test_bd_wgs_precise_round_trip
    # 阈值 1e-6 (~10cm): bd_gcj 与 gcj_bd 互逆的固有误差是其下限
    original = [121.468738, 31.247138]
    bd = Coordconver.wgs_bd(*original)
    back = Coordconver.bd_wgs_precise(*bd)
    assert_in_delta original[0], back[0], 1e-6
    assert_in_delta original[1], back[1], 1e-6
  end

  def test_precise_out_of_china_passthrough
    assert_equal [-0.13, 51.5], Coordconver.gcj_wgs_precise(-0.13, 51.5)
  end

  def test_precise_aliases
    assert_equal Coordconver.gcj_wgs_precise(121.473279, 31.245217),
      Coordconver.gcj02_wgs84_precise(121.473279, 31.245217)
    assert_equal Coordconver.bd_wgs_precise(121.479816, 31.251161),
      Coordconver.bd09_wgs84_precise(121.479816, 31.251161)
  end

  def test_invalid_pair_raises
    assert_raises(ArgumentError) { Coordconver.wgs_gcj("not-a-coord") }
    assert_raises(ArgumentError) { Coordconver.wgs_gcj({ lng: nil, lat: 31.0 }) }
  end
end
