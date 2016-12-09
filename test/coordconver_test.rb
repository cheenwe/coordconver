require 'test_helper'

class CoordconverTest < Minitest::Test
	def test_that_it_has_a_version_number
		refute_nil ::Coordconver::VERSION
	end

	# # http://www.gpsspg.com/maps.htm

	# |   坐标系      |   转换名称     |   方法|
	# |   ----------- |   ------- |   -----   | --------- |
	# |  BD-09 ->  GCJ-02  |    百度 -> 谷歌、高德  |   Coordconver.bd_gcj  |
	# |  BD-09 ->  WGS-84  |    百度 -> 地球坐标  |   Coordconver.bd_wgs   |
	# |  GCJ-02 -> WGS-84  |    谷歌、高德 -> 地球坐标  |    Coordconver.gcj_wgs   |
	# |  GCJ-02 -> BD-09  |    谷歌、高德 -> 百度  |    Coordconver.gcj_bd   |

	# |  WGS-84 -> BD-09  |    地球坐标 -> 百度  |    Coordconver.wgs_bd   |  121.46873833333332, 31.247138333333336 ->
	# |  WGS-84 -> GCJ-02 |    地球坐标 -> 谷歌、高德  |    Coordconver.wgs_gcj   |


	# # 原始点:
	# WGS-84 : 121.46873833333332, 31.247138333333336
	# # 上海市闸北区海宁路1127号

	# # http://lbsyun.baidu.com/jsdemo.htm#a5_2
	# # 百度点:
	# BD-09: 121.47981626441, 31.251161076123
	# # 上海市闸北区海宁路1141号

	# # http://lbs.amap.com/api/webservice/guide/api/convert/#convert
	# # 高德点:
	# GCJ-02: 121.473279,31.245217
	# # 上海市静安区海宁路

	# def test_bd_gcj
	# 	assert_equal [121.473279, 31.245217],
	# 		Coordconver.bd_gcj(121.47981626441, 31.251161076123)
	# end

	# def test_bd_wgs
	# 	assert_equal [121.46873833333332, 31.247138333333336],
	# 		Coordconver.bd_wgs(121.47981626441, 31.251161076123)
	# end

	# def test_gcj_wgs
	# 	assert_equal [121.46873833333332, 31.247138333333336],
	# 		Coordconver.gcj_wgs(121.473279, 31.245217)
	# end

	# def test_gcj_bd
	# 	assert_equal [121.47981626441, 31.251161076123],
	# 		Coordconver.gcj_bd(121.473279, 31.245217)
	# end

	def test_wgs_bd
		assert_equal [121.47981626441, 31.251161076123],
			Coordconver.wgs_bd(121.46873833333332, 31.247138333333336)
	end

	def test_wgs_gcj
		assert_equal [121.473279, 31.245217],
			Coordconver.wgs_gcj(121.46873833333332, 31.251161076123)
	end

end
