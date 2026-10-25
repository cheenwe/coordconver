require 'test_helper'

class ProjectionTest < Minitest::Test
  def test_zone_meridian_6
    assert_equal [21, 123], Coordconver.zone_meridian(121.47)
    assert_equal [20, 117], Coordconver.zone_meridian(116.39)
  end

  def test_zone_meridian_3
    assert_equal [40, 120], Coordconver.zone_meridian(121.47, width: 3)
    assert_equal [39, 117], Coordconver.zone_meridian(116.39, width: 3)
  end

  def test_zone_meridian_invalid_width
    assert_raises(ArgumentError) { Coordconver.zone_meridian(121.47, width: 5) }
  end

  # 上海 (121.47, 31.24), 3° 带 40 带, 中央经线 120°, 东坐标应明显大于 500km (在中央经线以东 ~140km)
  def test_gk_forward_shanghai
    x, y = Coordconver.gauss_kruger(121.47, 31.24, central_meridian: 120)
    assert_in_delta 640_045, x, 1.0
    assert_in_delta 3_458_515, y, 1.0
  end

  def test_gk_default_zone6
    # 默认 6° 带: 121.47 -> 21 带, 中央经线 123, 在中央经线以西, x < 500_000
    x, _y = Coordconver.gauss_kruger(121.47, 31.24)
    assert_operator x, :<, 500_000
  end

  def test_gk_false_easting_option
    x, y = Coordconver.gauss_kruger(121.47, 31.24, central_meridian: 120, false_easting: 0)
    assert_in_delta 140_045, x, 1.0
    assert_in_delta 3_458_515, y, 1.0
  end

  # 正反算往返, 各椭球与多个点位, 精度应优于 1e-7 度 (~1cm)
  def test_round_trip_cgcs2000
    points = [[121.47, 31.24], [116.39, 39.90], [104.08, 30.65], [87.62, 43.83]]
    points.each do |lng, lat|
      x, y = Coordconver.gauss_kruger(lng, lat, zone_width: 3)
      back_lng, back_lat = Coordconver.inverse_gauss_kruger(x, y, central_meridian: Coordconver.zone_meridian(lng, width: 3)[1])
      assert_in_delta lng, back_lng, 1e-7, "lng round trip failed for #{lng},#{lat}"
      assert_in_delta lat, back_lat, 1e-7, "lat round trip failed for #{lng},#{lat}"
    end
  end

  def test_round_trip_krassovsky_beijing54
    x, y = Coordconver.gauss_kruger(116.39, 39.90, zone_width: 3, ellipsoid: :krassovsky)
    back_lng, back_lat = Coordconver.inverse_gauss_kruger(
      x, y, central_meridian: 117, ellipsoid: :krassovsky
    )
    assert_in_delta 116.39, back_lng, 1e-7
    assert_in_delta 39.90, back_lat, 1e-7
  end

  def test_unknown_ellipsoid
    assert_raises(ArgumentError) { Coordconver.gauss_kruger(121.47, 31.24, ellipsoid: :bessel) }
  end

  def test_ellipsoids_close_but_not_identical
    a = Coordconver.gauss_kruger(121.47, 31.24, central_meridian: 120, ellipsoid: :cgcs2000)
    b = Coordconver.gauss_kruger(121.47, 31.24, central_meridian: 120, ellipsoid: :krassovsky)
    # 不同椭球下同一位置的平面坐标应相近但不同(差在米级)
    assert_in_delta a[0], b[0], 10.0
    refute_equal a[0], b[0]
  end
end
