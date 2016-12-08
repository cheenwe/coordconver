module Coordconver
	module CoordConver

		def self.included(base)
			base.send :extend, ClassMethods
		end

		# Class methods
		module ClassMethods
		# class << self

			# 定义一些常量
			X_PI = 3.14159265358979324 * 3000.0 / 180.0;
			PI = 3.1415926535897932384626;
			AA = 6378245.0; #a
			EE = 0.00669342162296594323; #e


		  def initialize(lng, lat)
		    @lng = lng.to_f
		    @lat = lat.to_f
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


			# 百度坐标系 (BD-09) 与 火星坐标系 (GCJ-02)的转换
		  # 即 百度 转 谷歌、高德
			def bd09_gcj02(bd_lon, bd_lat)
				lng= bd_lon.to_f
				lat= bd_lat.to_f

			  x = bd_lon - 0.0065;
			  y = bd_lat - 0.006;
			  z = Math.sqrt(x * x + y * y) - 0.00002 * Math.sin(y * x_PI);
			  theta = Math.atan2(y, x) - 0.000003 * Math.cos(x * x_PI);
			  gg_lng = z * Math.cos(theta);
			  gg_lat = z * Math.sin(theta);
			  return [gg_lng, gg_lat]
			end

		  # 火星坐标系 (GCJ-02) 与百度坐标系 (BD-09) 的转换
		  # 即谷歌、高德 转 百度
			def gcj02_bd09(lng, lat)
				lng= lng.to_f
				lat= lat.to_f

				z = Math.sqrt(lng * lng + lat * lat) + 0.00002 * Math.sin(lat * X_PI);
				theta = Math.atan2(lat, lng) + 0.000003 * Math.cos(lng * X_PI);
				bd_lng = z * Math.cos(theta) + 0.0065;
				bd_lat = z * Math.sin(theta) + 0.006;
				return [bd_lng, bd_lat]
			end


		 	# WGS84转GCj02
			def wgs84_gcj02(lng, lat)
				lng= lng.to_f
				lat= lat.to_f

				dlat = transformlat(lng - 105.0, lat - 35.0);
				dlng = transformlng(lng - 105.0, lat - 35.0);
				radlat = lat / 180.0 * PI;
				magic = Math.sin(radlat);
				magic = 1 - EE * magic * magic;
				sqrtmagic = Math.sqrt(magic);
				dlat = (dlat * 180.0) / ((AA * (1 - EE)) / (magic * sqrtmagic) * PI);
				dlng = (dlng * 180.0) / (AA / sqrtmagic * Math.cos(radlat) * PI);
				mglat = lat + dlat;
				mglng = lng + dlng;
				return [mglng, mglat]
			end

			# GCJ02 转换为 WGS84
			def gcj02_wgs84(lng, lat)
				lng= lng.to_f
				lat= lat.to_f

				dlat = transformlat(lng - 105.0, lat - 35.0);
				dlng = transformlng(lng - 105.0, lat - 35.0);
				radlat = lat / 180.0 * PI;
				magic = Math.sin(radlat);
				magic = 1 - EE * magic * magic;
				sqrtmagic = Math.sqrt(magic);
				dlat = (dlat * 180.0) / ((AA * (1 - EE)) / (magic * sqrtmagic) * PI);
				dlng = (dlng * 180.0) / (AA / sqrtmagic * Math.cos(radlat) * PI);
				mglat = lat + dlat;
				mglng = lng + dlng;
				return [lng * 2 - mglng, lat * 2 - mglat]
			end

			# WGS84 转换 BD08
			def wgs84_bd09(lng, lat)
				loca = wgs84_gcj02(lng, lat)
				gcj02_bd09(loca[0], loca[1])
			end

		end

	end
end
