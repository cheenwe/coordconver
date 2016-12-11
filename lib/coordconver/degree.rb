module Coordconver
	module Degree
		def self.included(base)
			base.extend(ClassMethods)
		end

		module ClassMethods

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
				[cal_degree(lng),cal_degree(lat)]
			end

			def cal_degree(n)
				"#{num(n)}°#{num(min(n))}′#{num(sec(n))}″"
			end


			# 获取分
			def get_min(n)
				n.split('°').last.to_f
			end

			# 获取秒
			def get_sec(n)
				n.split('′').last.to_f
			end

			# 度数转坐标
			def cal_undegree(n)
				(num(n) + get_min(n)/60 + get_sec(n)/3600).round(5)
			end

			def undegree(lng, lat)
				[cal_undegree(lng),cal_undegree(lat)]
			end

		end
	end
end
