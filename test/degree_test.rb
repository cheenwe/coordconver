require 'test_helper'

class DegreeTest < Minitest::Test
  # 参考值: 38.65777 -> 北纬N 38°39′27.97″, 104.08296 -> 东经E 104°4′58.66″

  def test_cal_degree
    assert_equal "38°39′27.97″", Coordconver.cal_degree(38.65777)
  end

  def test_cal_degree_precision_zero
    assert_equal "38°39′28″", Coordconver.cal_degree(38.65777, 0)
  end

  def test_cal_degree_negative
    assert_equal "-38°39′27.97″", Coordconver.cal_degree(-38.65777)
  end

  def test_degree
    assert_equal ["38°39′27.97″", "104°4′58.66″"],
      Coordconver.degree(38.65777, 104.08296)
  end

  def test_cal_undegree
    assert_equal 104.082961, Coordconver.cal_undegree("104°4′58.66″")
  end

  def test_cal_undegree_negative
    assert_equal -38.657769, Coordconver.cal_undegree("-38°39′27.97″")
  end

  def test_cal_undegree_without_seconds
    assert_in_delta 38.65, Coordconver.cal_undegree("38°39′"), 0.0001
  end

  def test_cal_undegree_dms_style
    assert_equal 38.657769, Coordconver.cal_undegree("38d39m27.97s")
  end

  def test_cal_undegree_colon_style
    assert_equal 38.657769, Coordconver.cal_undegree("38:39:27.97")
  end

  def test_undegree
    assert_equal [38.657769, 104.082961],
      Coordconver.undegree("38°39′27.97″", "104°4′58.66″")
  end

  def test_round_trip
    value = 121.473279
    assert_in_delta value, Coordconver.cal_undegree(Coordconver.cal_degree(value)), 0.00001
  end

  # 兼容旧挂载方式: 通过 Coordconver 单例与 Degree 模块两种途径都可调用
  def test_module_access
    assert_equal Coordconver::Degree.degree(38.65777, 104.08296),
      Coordconver.degree(38.65777, 104.08296)
  end
end
