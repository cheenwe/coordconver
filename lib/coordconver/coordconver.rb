module Coordconver
	module Coordconver

		def self.included(base)
			base.extend(ClassMethods)
		end

		# 定义一些常量
		X_PI = 3.14159265358979324 * 3000.0 / 180.0
		PI = 3.1415926535897932384626
		AA = 6378245.0 #a
		EE = 0.00669342162296594323 #e

		module ClassMethods

			def transformlat(lng, lat)
				ret = -100.0 + 2.0 * lng + 3.0 * lat + 0.2 * lat * lat + 0.1 * lng * lat + 0.2 * Math.sqrt((lng).abs);
				ret += (20.0 * Math.sin(6.0 * lng * PI) + 20.0 * Math.sin(2.0 * lng * PI)) * 2.0 / 3.0;
				ret += (20.0 * Math.sin(lat * PI) + 40.0 * Math.sin(lat / 3.0 * PI)) * 2.0 / 3.0;
				ret += (160.0 * Math.sin(lat / 12.0 * PI) + 320 * Math.sin(lat * PI / 30.0)) * 2.0 / 3.0;
				return ret
			end

			def transformlng(lng, lat)
				ret = 300.0 + lng + 2.0 * lat + 0.1 * lng * lng + 0.1 * lng * lat + 0.1 * Math.sqrt((lng).abs);
				ret += (20.0 * Math.sin(6.0 * lng * PI) + 20.0 * Math.sin(2.0 * lng * PI)) * 2.0 / 3.0;
				ret += (20.0 * Math.sin(lng * PI) + 40.0 * Math.sin(lng / 3.0 * PI)) * 2.0 / 3.0;
				ret += (150.0 * Math.sin(lng / 12.0 * PI) + 300.0 * Math.sin(lng / 30.0 * PI)) * 2.0 / 3.0;
			end

			# 百度坐标系 (BD-09)  -> 火星坐标系 (GCJ-02)
			# 即 百度  ->  谷歌、高德
			# Coordconver.bd_gcj(lng, lat)
			def bd_gcj(lng, lat)
				x = lng - 0.0065;
				y = lat - 0.006;
				z = Math.sqrt(x * x + y * y) - 0.00002 * Math.sin(y * X_PI);
				theta = Math.atan2(y, x) - 0.000003 * Math.cos(x * X_PI);
				gg_lng = z * Math.cos(theta);
				gg_lat = z * Math.sin(theta);
				return [gg_lng, gg_lat]
			end

			# 百度坐标系 (BD-09)  -> 地球坐标 (WGS-84)
			# 即 百度  -> 地球坐标
			# Coordconver.bd_wgs(lng, lat)
			def bd_wgs(lng, lat)
				loca = wgs_gcj(lng, lat)
				gcj_bd(loca[0], loca[1])
			end

			# 火星坐标系 (GCJ02)  -> 地球坐标 (WGS-84)
			# 即  谷歌、高德 -> 地球坐标
			# Coordconver.gcj_wgs(lng, lat)
			def gcj_wgs(lng, lat)
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

			# 火星坐标系 (GCJ-02) 与百度坐标系 (BD-09)
			# 即  谷歌、高德 -> 百度
			# Coordconver.gcj_bd(lng, lat)
			def gcj_bd(lng, lat)
				z = Math.sqrt(lng * lng + lat * lat) + 0.00002 * Math.sin(lat * X_PI);
				theta = Math.atan2(lat, lng) + 0.000003 * Math.cos(lng * X_PI);
				bd_lng = z * Math.cos(theta) + 0.0065;
				bd_lat = z * Math.sin(theta) + 0.006;
				return [bd_lng, bd_lat]
			end

			# 地球坐标 ( WGS-84) 与百度坐标系 (BD-09)
			# 即  地球坐标 -> 百度
			# Coordconver.wgs_bd(lng, lat)
			def wgs_bd(lng, lat)
				loca = wgs_gcj(lng, lat)
				gcj_bd(loca[0], loca[1])
			end

			# 地球坐标 ( WGS-84) 与火星坐标系 (GCJ-02)
			# 即  地球坐标 -> 谷歌、高德
			# Coordconver.wgs_gcj(lng, lat)
			def wgs_gcj(lng, lat)
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
		end
	end
end
