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
end
