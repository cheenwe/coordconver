require 'net/http'
require 'json'

module Coordconver
  module Utils
    class Http

      DEFAULT_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.98 Safari/537.36"
      DEFAULT_OPEN_TIMEOUT = 20
      DEFAULT_READ_TIMEOUT = 120
      DEFAULT_RETRY_TIMES = 3
      RETRY_SLEEP_TIME = 3

      HTTP_VERB_MAP = {
        get:    Net::HTTP::Get,
        post:   Net::HTTP::Post,
        put:    Net::HTTP::Put,
        delete: Net::HTTP::Delete
      }

      DEFAULT_HEADERS = {
        'user-agent' => DEFAULT_USER_AGENT,
        'accept' => 'application/json',
        'content-type' => 'application/json',
        'connection' => 'close'
      }

      def initialize(method, url, params: nil, body: nil, headers: {}, opts: {})
        method = method.downcase.to_sym
        err_msg = "http method #{method} is not supported"
        raise err_msg unless HTTP_VERB_MAP.keys.include?(method)
        @uri = URI(url)
        @uri.query = URI.encode_www_form(params) unless params.nil?
        @request = prepare_request(method, body, headers)
        @opts = opts
      end

      def send_request
        tries ||= DEFAULT_RETRY_TIMES
        opts ||= default_opts.merge @opts
        Net::HTTP.start(@uri.host, @uri.port, opts) do |http|
          http.request(@request)
        end
      # if raise Timeout::Error retry it for 3 times
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        (tries -= 1).zero? ? (raise "Time out") : retry
      end

      # def basic_auth(user = nil, password = nil)
      #   user ||= Config.settings[:app_key]
      #   password ||= Config.settings[:master_secret]
      #   @request.basic_auth(user, password)
      #   self
      # end

      private

        def prepare_request(method, body, headers)
          headers = DEFAULT_HEADERS.merge(headers)
          request = HTTP_VERB_MAP[method].new @uri
          request.initialize_http_header(headers)
          request.body = body.to_json unless body.nil?
          request
        end


        def default_opts
          {
            use_ssl: 'https' == @uri.scheme,
            open_timeout: DEFAULT_OPEN_TIMEOUT,
            read_timeout: DEFAULT_READ_TIMEOUT
          }
        end

    end
  end
end
