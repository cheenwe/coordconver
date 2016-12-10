require 'test_helper'

class DegreeTest < Minitest::Test

	# 38.65777,104.08296 北纬N38°39′27.97″ 东经E104°04′58.66″
	def test_cal_degree
		assert_equal "38°39’27″" ,
			Coordconver.cal_degree(38.65777)
	end

	def test_cal_degree_1
		assert_equal "104°04′58″" ,
			Coordconver.cal_degree(104.08296)
	end

	# 38.65777,104.08296 北纬N38°39′27.97″ 东经E104°04′58.66″
	def test_cal_undegree
		assert_equal "38.65777" ,
			Coordconver.cal_degree("38°39’27″")
	end

end
