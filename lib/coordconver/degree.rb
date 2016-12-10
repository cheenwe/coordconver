module Coordconver
	module Degree
		def self.included(base)
			base.extend(ClassMethods)
		end

		module ClassMethods

			# 地形图坐标系：我国的地形图采用高斯－克吕格平面直角坐标系。在该坐标系中，横轴：赤道，用Ｙ表示；纵轴：中央经线，用Ｘ表示；坐标原点：中央经线与赤道的交点，用0表示。赤道以南为负，以北为正；中央经线以东为正，以西为负。我国位于北半球，故纵坐标均为正值，但为避免中央经度线以西为负值的情况，将坐标纵轴西移500公里。

			# 北京54坐标系：1954年我国在北京设立了大地坐标原点，采用克拉索夫斯基椭球体，依此计算出来的各大地控制点的坐标，称为北京54坐标系。
			# GS84坐标系：即世界通用的经纬度坐标系。

			# 经纬度表示：1884年国际经度会议规定，以通过英国伦敦格林威治天文台子午仪中心的经线为0°经线。从0°经线往东叫东经，往西叫西经，东、西各分180°。习惯上以西经20°和东经160°为分界把地球分为东西两个半球。假如从地轴的正中间将地球切成南北两半，上边的一半叫北半球，下边的一半叫南半球。被切的这个平面，叫赤道面。赤道面与地球表面相交的线叫赤道。纬线从赤道往两极越来越短，到了两极就缩小成一个点了。科学家们把赤道定为0°纬线，从赤道向两极各分为90°，赤道以南叫南纬，赤道以北叫北纬。在计算机或GPS上经纬度经常用度、分、秒和度.度、分.分、秒.秒的混合方式进行表示，度、分、秒间的进制是60进制，度.度、分.分、秒.秒的进制是100进制，换算时一定要注意。可以近似地认为每个纬度之间的距离是不变的111KM,每分间 1.85KM，每秒间31.8M。经度间的距离随纬度增高逐渐减小，可按以下公式计算：

			# Decimal Degrees = Degrees + minutes/60 + seconds/3600
			# 例：57°55’56.6″ =57+55/60+56.6/3600=57.9323888888888
			# 114°65’24.6″=114+65/60+24.6/3600=115.00683333333333


			# 取整数位
			def num(n)
				n.to_i
			end

			# 取小数数位 Decimal digit
			def dig(n)
				n.to_f-num(n)
			end

			# 计算分
			def min(n)
				dig(n)*60
			end

			# 计算秒
			def sec(n)
				(min(n)-num(min(n)))*60
			end



			# 坐标转度数
			def degree(lng, lat)
				[cal_degrees(lng),cal_degrees(lat)]
			end

			def cal_degree(n)
				"#{num(n)}°#{num(min(n))}’#{num(sec(n))}″"
			end


			# 获取分
			def get_min(n)
				n.split('°').last.to_f
			end

			# 获取秒
			def get_sec(n)
				n.split('’').last.to_f
			end

			# 度数转坐标
			def cal_undegree(n)
				num(n) + get_min(n)/60 + get_sec(n)/3600
			end

			def undegree(lng, lat)
				[cal_undegrees(lng),cal_undegrees(lat)]
			end


		end
	end
end
