require 'test_helper'

class DegreeTest < Minitest::Test
	#百度地图api在线转换
	# 116.480881,39.989410-->北京市朝阳区阜通东大街6号

	# Coordconver::Gaode.geo("北京市朝阳区阜通东大街6号") #高德地图api在线转换

	def test_gaode_regeo
		assert_equal "北京市朝阳区望京街道方恒国际中心A座北京方恒假日酒店" ,
			Coordconver::Client.new(["uzInpBxCpE0DiPnln3UbDv4OQTdOgmXu"],["2164e7f8798dcafae3eaa6e74d464a5c"])&&Coordconver::Gaode.regeo(116.480881,39.989410)['regeocode']["formatted_address"]
	end

	def test_gaode_geo
		assert_equal "116.480724,39.989584",
			Coordconver::Client.new(["uzInpBxCpE0DiPnln3UbDv4OQTdOgmXu"],["2164e7f8798dcafae3eaa6e74d464a5c"])&&Coordconver::Gaode.geo("北京方恒国际中心A座")["geocodes"][0]["location"]
	end

	def test_baidu_regeo
		assert_equal "北京市海淀区中关村大街27号1101-08室" ,
			Coordconver::Client.new(["uzInpBxCpE0DiPnln3UbDv4OQTdOgmXu"],["2164e7f8798dcafae3eaa6e74d464a5c"])&&Coordconver::Baidu.regeo(116.32298699999993,39.98342407140365)["result"]["formatted_address"]

	end

	def test_baidu_geo
		assert_equal [116.4886760717474, 39.99562822882448],
			Coordconver::Client.new(["uzInpBxCpE0DiPnln3UbDv4OQTdOgmXu"],["2164e7f8798dcafae3eaa6e74d464a5c"])&& a=Coordconver::Baidu.geo("北京市朝阳区阜通东大街6号")["result"]["location"].values
	end

end
