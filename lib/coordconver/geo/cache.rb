# frozen_string_literal: true

module Coordconver
  module Geo
    # 进程内 LRU + TTL 缓存, 用于地理编码结果去重以节省配额。
    # 默认关闭, 通过 config.cache = true 开启; 可配置 cache_ttl / cache_size。
    module Cache
      DEFAULT_TTL = 3600
      DEFAULT_SIZE = 1024

      @store = {}
      @mutex = Mutex.new

      class << self
        def enabled?
          Configuration.configured? && Configuration.settings[:cache] ? true : false
        end

        # 命中且未过期返回值, 否则返回 nil
        def get(key)
          return nil unless enabled?

          @mutex.synchronize do
            entry = @store[key]
            return nil unless entry
            return nil if Time.now - entry[:at] > ttl

            @store.delete(key)
            @store[key] = entry # LRU: 重新插入到队尾
            entry[:value]
          end
        end

        # 存入并返回 value; 未启用时原样返回 value
        def set(key, value)
          return value unless enabled?

          @mutex.synchronize do
            @store.delete(key)
            @store[key] = { at: Time.now, value: value }
            @store.shift while @store.size > size
            value
          end
        end

        def delete(key)
          @mutex.synchronize { @store.delete(key) }
        end

        def clear!
          @mutex.synchronize { @store.clear }
        end

        private

        def ttl
          Configuration.settings[:cache_ttl] || DEFAULT_TTL
        end

        def size
          Configuration.settings[:cache_size] || DEFAULT_SIZE
        end
      end
    end
  end
end
