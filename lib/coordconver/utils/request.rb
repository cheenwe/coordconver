# frozen_string_literal: true

module Coordconver
  module Utils
    module Request
      extend self

      def get(url, params: nil, headers: {})
        send_request(:get, url, params: params, headers: headers)
      end

      def post(url, body: nil, headers: {})
        send_request(:post, url, body: body, headers: headers)
      end

      def put(url, body: nil, headers: {})
        send_request(:put, url, body: body, headers: headers)
      end

      def delete(url, params: nil, headers: {})
        send_request(:delete, url, params: params, headers: headers)
      end

      def send_request(method, url, params: nil, body: nil, headers: {})
        raw_response = Http.new(
          method.to_sym,
          url,
          params: params,
          body: body,
          headers: headers
        ).send_request

        parse_body(raw_response.body)
      rescue JSON::ParserError => e
        raise NetworkError, "响应不是合法 JSON: #{e.message}"
      end

      def parse_body(body)
        JSON.parse(body)
      end
    end
  end
end
