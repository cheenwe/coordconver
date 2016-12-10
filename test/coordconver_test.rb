require 'test_helper'

class CoordconverTest < Minitest::Test

	# 坐标点互转： http://www.gpsspg.com/maps.htm

	# # 原始点:
	# WGS-84 : 121.46873833333332, 31.247138333333336
	# 121.468738,31.247138
	# # 上海市闸北区海宁路1127号

	# # http://lbsyun.baidu.com/jsdemo.htm#a5_2
	# # 百度点:
	# BD-09: 121.47981626441, 31.251161076123
	# 121.47981626441,31.251161076123
	# # 上海市闸北区海宁路1141号

	# # http://lbs.amap.com/api/webservice/guide/api/convert/#convert
	# # 高德点:
	# GCJ-02: 121.473279,31.245217
	# 121.473278,31.245217
	# # 上海市静安区海宁路


	# http://lbsyun.baidu.com/jsdemo.htm#a5_2
	# var x = 116.32715863448607;
  # var y = 39.990912172420714;
	# x: 116.33993386792, y: 39.997907973792
	def test_bd_wgs
		assert_equal [116.33993386792, 39.997907973792].map! { |a| a.round(5) },
			Coordconver.bd_wgs(116.32715863448607, 39.990912172420714).map! { |a| a.round(5) }
	end

	def test_gcj_wgs
		assert_equal [121.46873833333332, 31.247138333333336].map! { |a| a.round(3) },
			Coordconver.gcj_wgs(121.473279, 31.245217).map! { |a| a.round(3) }
	end

	def test_gcj_bd
		assert_equal [121.47981626441, 31.251161076123].map! { |a| a.round(4) },
			Coordconver.gcj_bd(121.473279, 31.245217).map! { |a| a.round(4) }
	end


	# WGS-84 : 121.46873833333332, 31.247138333333336
	# BD-09: 121.47981626441, 31.251161076123

	def test_wgs_bd
		assert_equal [121.47981626441, 31.251161076123].map! { |a| a.round(4) },
			Coordconver.wgs_bd(121.46873833333332, 31.247138333333336).map! { |a| a.round(4) }
	end

	# 百度地图 在小数后五位的情况下能保持坐标点的准确性，四位保持道路准确性
	# 0. 121.4798,31.2511：商圈(西藏北路,海宁路,火车站) 结构化数据(上海市, 上海市, 闸北区, 海宁路, 1139号)
	# 1. 121.47981,31.25115：商圈(西藏北路,海宁路,火车站) 结构化数据(上海市, 上海市, 闸北区, 海宁路, 1141号)
	# 2. 121.479808223763,31.25115814844421：商圈(西藏北路,海宁路,火车站) 结构化数据(上海市, 上海市, 闸北区, 海宁路, 1141号)

	# def test_wgs_gcj
	# 	assert_equal [121.473279, 31.245217].map! { |a| a.round(4) },
	# 		Coordconver.wgs_gcj(121.468738, 31.251161).map! { |a| a.round(4) }
	# end


	# 高德地图转换示例
	# http://lbs.amap.com/api/webservice/guide/api/convert/#convert
	# 116.481499,39.990475|116.481499,39.990375

	# WGS-84 -> GCJ-02
	# "116.487586,39.991755;116.487586,39.991654"
	def test_wgs_gcj
		assert_equal [116.487586,39.991755].map! { |a| a.round(4) },
			Coordconver.wgs_gcj(116.481499,39.990475).map! { |a| a.round(4) }
	end

	def test_wgs_gcj_1
		assert_equal [116.487586,39.991654],
			Coordconver.wgs_gcj(116.481499,39.990375).map! { |a| a.round(6) }
	end

	# 116.47489552,39.98471717;116.47489555,39.98461718"
	def test_bd_gcj
		assert_equal [116.47489552,39.98471717].map! { |a| a.round(5) },
			Coordconver.bd_gcj(116.481499,39.990475).map! { |a| a.round(5) }
	end

	def test_bd_gcj_1
		assert_equal [116.47489555,39.98461718].map! { |a| a.round(5) },
			Coordconver.bd_gcj(116.481499,39.990375).map! { |a| a.round(5) }
	end

	# 38.65777,104.08296 北纬N38°39′27.97″ 东经E104°04′58.66″
	def test_cal_degree
		assert_equal "38°39’27″" ,
			Coordconver.cal_degree(38.65777)
	end
end
