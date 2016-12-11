require 'test_helper'

class DegreeTest < Minitest::Test

	# 38.65777,104.08296 北纬N38°39′27.97″ 东经E104°4′58.66″
	# #
	# lng, lat = 38.65777,104.08296
	# lng_degree, lat_degree = "38°39′27.97″","104°4′58.66″"

	def test_cal_degree
		assert_equal "38°39′27″" ,
			Coordconver.cal_degree(38.65777)
	end

	def test_cal_degree_1
		assert_equal "104°4′58″" ,
			Coordconver.cal_degree(104.08296)
	end

	def test_cal_undegree_1
		assert_equal 104.08296 ,
			Coordconver.cal_undegree("104°4′58.66″")
	end

	def test_degree
		assert_equal ["38°39′27″","104°4′58″"],
			Coordconver.degree(38.65777,104.08296)
	end

	def test_undegree
		assert_equal [38.65777,104.08296],
			Coordconver.undegree("38°39′27.97″","104°4′58.66″")
	end
end
