require "coordconver/version"

module Coordconver

	# 定义一些常量
	X_PI = 3.14159265358979324 * 3000.0 / 180.0;
	PI = 3.1415926535897932384626;
	AA = 6378245.0; #a
	EE = 0.00669342162296594323; #e


  def initialize(lng, lat)
    @lng = lng.to_f
    @lat = lat.to_f
    puts '>>>>in'
  end

	def transformlat(lng, lat)
		lng= lng.to_f
		lat= lat.to_f

    ret = -100.0 + 2.0 * lng + 3.0 * lat + 0.2 * lat * lat + 0.1 * lng * lat + 0.2 * Math.sqrt((lng).abs);
    ret += (20.0 * Math.sin(6.0 * lng * PI) + 20.0 * Math.sin(2.0 * lng * PI)) * 2.0 / 3.0;
    ret += (20.0 * Math.sin(lat * PI) + 40.0 * Math.sin(lat / 3.0 * PI)) * 2.0 / 3.0;
    ret += (160.0 * Math.sin(lat / 12.0 * PI) + 320 * Math.sin(lat * PI / 30.0)) * 2.0 / 3.0;
    return ret
	end

	def transformlng(lng, lat)
		lng= lng.to_f
		lat= lat.to_f

		ret = 300.0 + lng + 2.0 * lat + 0.1 * lng * lng + 0.1 * lng * lat + 0.1 * Math.sqrt((lng).abs);
		ret += (20.0 * Math.sin(6.0 * lng * PI) + 20.0 * Math.sin(2.0 * lng * PI)) * 2.0 / 3.0;
		ret += (20.0 * Math.sin(lng * PI) + 40.0 * Math.sin(lng / 3.0 * PI)) * 2.0 / 3.0;
		ret += (150.0 * Math.sin(lng / 12.0 * PI) + 300.0 * Math.sin(lng / 30.0 * PI)) * 2.0 / 3.0;
	end


	# bd09_gcj02("121.46873833333332", "31.247138333333336")

	#  百度坐标系 (BD-09) 与 火星坐标系 (GCJ-02)的转换
  #  即 百度 转 谷歌、高德
	def self.bd09_gcj02(@lng, @lat)
		puts @lng
		puts @lng.class

	  x = @lng - 0.0065;
	  y = @lat - 0.006;
	  z = Math.sqrt(x * x + y * y) - 0.00002 * Math.sin(y * x_PI);
	  theta = Math.atan2(y, x) - 0.000003 * Math.cos(x * x_PI);
	  gg_lng = z * Math.cos(theta);
	  gg_lat = z * Math.sin(theta);
	  return [gg_lng, gg_lat]
	end


end
