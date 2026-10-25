# frozen_string_literal: true

module Coordconver
  module Geo
    # 百度/高德/腾讯 API 的统一调度层:
    # 组装 key -> LRU 缓存 -> 请求 -> 识别 key 类失败 -> 轮换下一个 key 重试。
    module Api
      # provider:    :baidu / :gaode / :tencent
      # params:      业务参数(不含 key)
      # key_param:   key 参数名 (:ak / :key)
      # sign:        可选 Proc, 对含 key 的完整参数做签名(百度 SN 校验)
      # bad_result:  Proc, 判断响应是否属于"key 无效/配额超限"类失败(应轮换 key)
      def self.call(provider:, url:, params:, key_param:, sign: nil, bad_result:)
        keys = Configuration.keys_for(provider)
        attempts = 0
        loop do
          key = KeyPool.next_key(provider, keys)
          full_params = params.merge(key_param => key)
          full_params = sign.call(full_params) if sign
          cache_key = [provider, url, full_params]

          hit = Cache.get(cache_key)
          if hit
            return hit unless bad_result.call(hit)

            Cache.delete(cache_key) # 防御: 不应缓存过失败响应
            next
          end

          response = Utils::Request.get(url, params: full_params)
          return Cache.set(cache_key, response) unless bad_result.call(response)

          KeyPool.mark_bad(provider, key)
          attempts += 1
          if attempts >= keys.size
            raise ApiError.new(
              "#{provider} 请求失败: 所有 #{keys.size} 个 key 均无效或配额超限",
              code: provider, raw: response
            )
          end
        end
      end
    end
  end
end
