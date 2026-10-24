# frozen_string_literal: true

require "net/http"
require "json"

module Coordconver
  module Utils
    # 轻量 HTTP 客户端, 仅依赖标准库。
    # 网络层失败(超时/连接错误/非 2xx)会自动重试, 重试耗尽后抛出 Coordconver::NetworkError。
    class Http
      DEFAULT_OPEN_TIMEOUT = 5
      DEFAULT_READ_TIMEOUT = 10
      DEFAULT_RETRY_TIMES = 3
      RETRY_BASE_SLEEP = 0.5

      HTTP_VERB_MAP = {
        get: Net::HTTP::Get,
        post: Net::HTTP::Post,
        put: Net::HTTP::Put,
        delete: Net::HTTP::Delete
      }.freeze

      DEFAULT_HEADERS = {
        "user-agent" => "coordconver/#{Coordconver::VERSION} (+https://github.com/cheenwe/coordconver)",
        "accept" => "application/json"
      }.freeze

      RETRYABLE_ERRORS = [
        Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET,
        Errno::ECONNREFUSED, Errno::ETIMEDOUT, SocketError, EOFError
      ].freeze

      def initialize(method, url, params: nil, body: nil, headers: {})
        method = method.to_s.downcase.to_sym
        raise ArgumentError, "不支持的 HTTP method: #{method}" unless HTTP_VERB_MAP.key?(method)

        @uri = URI(url)
        @uri.query = build_query(params) if params && !params.empty?
        @method = method
        @body = body
        @headers = headers
      end

      def send_request
        attempts = 0
        begin
          attempts += 1
          perform
        rescue *RETRYABLE_ERRORS => e
          raise NetworkError, "#{@uri.host} 请求失败: #{e.class}: #{e.message}" if attempts >= DEFAULT_RETRY_TIMES

          sleep(RETRY_BASE_SLEEP * (2**(attempts - 1)))
          retry
        end
      end

      private

      def perform
        opts = {
          use_ssl: @uri.scheme == "https",
          open_timeout: open_timeout,
          read_timeout: read_timeout
        }
        Net::HTTP.start(@uri.host, @uri.port, **opts) do |http|
          response = http.request(build_request)
          unless response.is_a?(Net::HTTPSuccess)
            raise NetworkError, "#{@uri.host} 返回 HTTP #{response.code}"
          end

          response
        end
      end

      def build_request
        request = HTTP_VERB_MAP[@method].new(@uri)
        request.initialize_http_header(DEFAULT_HEADERS.merge(@headers))
        request.body = @body.to_json if @body
        request
      end

      def build_query(params)
        URI.encode_www_form(params)
      end

      def open_timeout
        configured = Coordconver::Geo::Configuration.configured? && Coordconver::Geo::Configuration.settings[:open_timeout]
        configured || DEFAULT_OPEN_TIMEOUT
      end

      def read_timeout
        configured = Coordconver::Geo::Configuration.configured? && Coordconver::Geo::Configuration.settings[:read_timeout]
        configured || DEFAULT_READ_TIMEOUT
      end
    end
  end
end
