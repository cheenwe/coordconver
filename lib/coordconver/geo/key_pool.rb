# frozen_string_literal: true

module Coordconver
  module Geo
    # 多 key 智能轮询: round-robin 取 key, 请求失败(配额超限/无效)时摘除该 key,
    # 冷却时间过后自动恢复。线程安全。
    class KeyPool
      # 被摘除 key 的冷却时长(秒), 覆盖"每秒/每日配额超限"两类场景
      COOLDOWN = 300

      def initialize
        @mutex = Mutex.new
        @index = {}
        @disabled_at = {}
      end

      # 轮询取下一个可用 key; 全部处于冷却期时抛出 ApiError
      def next_key(provider, keys)
        @mutex.synchronize do
          purge_expired(Time.now)
          enabled = keys.reject { |k| @disabled_at[[provider, k]] }
          if enabled.empty?
            raise ApiError, "所有 #{provider} key 均不可用(配额超限或无效), 请更换或补充 key"
          end

          @index[provider] = (@index[provider] ||= -1) + 1
          enabled[@index[provider] % enabled.size]
        end
      end

      def mark_bad(provider, key)
        @mutex.synchronize { @disabled_at[[provider, key]] = Time.now }
      end

      def disabled?(provider, key)
        @mutex.synchronize do
          purge_expired(Time.now)
          !@disabled_at[[provider, key]].nil?
        end
      end

      def reset!
        @mutex.synchronize do
          @index.clear
          @disabled_at.clear
        end
      end

      private

      def purge_expired(now)
        @disabled_at.reject! { |_, t| now - t > COOLDOWN }
      end

      class << self
        def instance
          @instance ||= new
        end

        def next_key(provider, keys)
          instance.next_key(provider, keys)
        end

        def mark_bad(provider, key)
          instance.mark_bad(provider, key)
        end

        def disabled?(provider, key)
          instance.disabled?(provider, key)
        end

        def reset!
          instance.reset!
        end
      end
    end
  end
end
