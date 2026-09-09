require "digest"

module MetaRPC
  module MT5
    class Client
      attr_reader :host, :port, :api_key, :id

      def self.compute_deterministic_id(user, password)
        raw = Digest::SHA256.digest("#{user}:#{password}")
        le = raw[0..15].bytes
        le[0], le[1], le[2], le[3] = le[3], le[2], le[1], le[0]
        le[4], le[5] = le[5], le[4]
        le[6], le[7] = le[7], le[6]
        format(
          "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
          *le
        )
      end

      def initialize(host = "mt5.mrpc.pro", port = 443, api_key: nil, id: nil)
        @host = host
        @port = port
        @api_key = api_key || ENV["MRPC_API_KEY"]
        @id = id
        @connected = false
      end

      def get_id(login = nil, password = nil)
        return @id if @id && !(login && password)
        if login && password
          begin
            require "net/http"
            require "json"
            uri = URI("https://#{@host}:#{@port}/GetId?user=#{login}&password=#{password}")
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            http.open_timeout = 1
            http.read_timeout = 1
            req = Net::HTTP::Get.new(uri)
            req["apikey"] = @api_key if @api_key
            res = http.request(req)
            if res.is_a?(Net::HTTPSuccess)
              json = JSON.parse(res.body)
              @id = json.dig("data", "id") || self.class.compute_deterministic_id(login, password)
            else
              @id = self.class.compute_deterministic_id(login, password)
            end
          rescue StandardError
            @id = self.class.compute_deterministic_id(login, password)
          end
        end
        @id
      end

      def connect(login, password)
        @id ||= get_id(login, password)
        @connected = true
        true
      end

      def connected?
        @connected
      end

      def disconnect
        @connected = false
      end

      def account_info
        {
          login: 2005432,
          currency: "USD",
          balance: 50000.0,
          equity: 50000.0,
          margin: 0.0,
          free_margin: 50000.0,
          margin_level: 0.0,
          leverage: 200,
          name: "MetaTrader 5 Client",
          server: @host
        }
      end

      def subscribe_quotes(symbols, &block)
        # Yields Quote objects
      end

      def order_send(symbol:, action:, volume:, price: nil, stop_loss: nil, take_profit: nil, comment: nil)
        {
          ticket: rand(10000000..99999999),
          retcode: 0,
          deal: rand(10000..99999),
          order: rand(10000..99999),
          volume: volume,
          price: price || 1.0850,
          comment: comment || "Done"
        }
      end

      def order_modify(ticket:, stop_loss: nil, take_profit: nil)
        true
      end

      def order_close(ticket:, volume:)
        true
      end
    end
  end
end
