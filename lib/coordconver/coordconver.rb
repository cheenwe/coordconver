module Coordconver
	class Coordconver

		def self.included(base)
			base.extend(ClassMethods)
		end

		module ClassMethods

			def abc
				puts ">>>>>>>"

			end
		end
	end
end
