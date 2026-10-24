# frozen_string_literal: true

module Coordconver
  # 统一错误基类, 便于业务侧 rescue Coordconver::Error
  class Error < StandardError; end

  # 缺少 API key 等配置问题时抛出
  class ConfigurationError < Error; end

  # 网络超时、连接失败、响应非 JSON 时抛出
  class NetworkError < Error; end

  # 服务端返回业务错误(如 key 无效、配额超限)时抛出
  class ApiError < Error
    attr_reader :code, :raw

    def initialize(message = nil, code: nil, raw: nil)
      super(message)
      @code = code
      @raw = raw
    end
  end
end
