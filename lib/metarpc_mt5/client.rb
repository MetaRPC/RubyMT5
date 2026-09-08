module MetaRPC
  module MT5
    class Client
      attr_reader :host, :port

      def initialize(host, port = 443)
        @host = host
        @port = port
        @connected = false
      end

      def connect(login, password)
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
