module Binance
  module Api
    class Margin
      class << self
        def all!(limit: 500, orderId: nil, recvWindow: 5000, symbol: nil)
          raise Error.new(message: "max limit is 1000") unless limit <= 1000
          raise Error.new(message: "symbol is required") if symbol.nil?
          timestamp = Configuration.timestamp
          params = { limit: limit, orderId: orderId, recvWindow: recvWindow, symbol: symbol, timestamp: timestamp }
          Request.send!(api_key_type: :read_info, path: "/sapi/v1/margin/allOrders",
                        params: params.delete_if { |key, value| value.nil? },
                        security_type: :user_data)
        end

        # Be careful when accessing without a symbol!
        def all_open!(recvWindow: 5000, symbol: nil)
          timestamp = Configuration.timestamp
          params = { recvWindow: recvWindow, symbol: symbol, timestamp: timestamp }
          Request.send!(api_key_type: :read_info, path: '/sapi/v1/margin/openOrders',
                        params: params, security_type: :user_data)
        end

        def cancel!(orderId: nil, originalClientOrderId: nil, newClientOrderId: nil, recvWindow: nil, symbol: nil)
          raise Error.new(message: "symbol is required") if symbol.nil?
          raise Error.new(message: "either orderid or originalclientorderid " \
            "is required") if orderId.nil? && originalClientOrderId.nil?
          timestamp = Configuration.timestamp
          params = { orderId: orderId, origClientOrderId: originalClientOrderId,
                     newClientOrderId: newClientOrderId, recvWindow: recvWindow,
                     symbol: symbol, timestamp: timestamp }.delete_if { |key, value| value.nil? }
          Request.send!(api_key_type: :trading, method: :delete, path: "/sapi/v1/margin/order",
                        params: params, security_type: :trade)
        end

        def create!(icebergQuantity: nil, newClientOrderId: nil, newOrderResponseType: nil,
                    price: nil, quantity: nil, recvWindow: nil, stopPrice: nil, symbol: nil,
                    side: nil, type: nil, timeInForce: nil, test: false)
          timestamp = Configuration.timestamp
          params = { 
            icebergQty: icebergQuantity, newClientOrderId: newClientOrderId,
            newOrderRespType: newOrderResponseType, price: price, quantity: quantity,
            recvWindow: recvWindow, stopPrice: stopPrice, symbol: symbol, side: side,
            type: type, timeInForce: timeInForce, timestamp: timestamp
          }.delete_if { |key, value| value.nil? }
          ensure_required_create_keys!(params: params)
          path = "/sapi/v1/margin/order#{'/test' if test}"
          Request.send!(api_key_type: :trading, method: :post, path: path,
                        params: params, security_type: :trade)
        end

        def max_borrowable!(recvWindow: 5000, asset: nil)
          raise Error.new(message: "asset is required") if asset.nil?
          timestamp = Configuration.timestamp
          params = { recvWindow: recvWindow, asset: asset, timestamp: timestamp }
          Request.send!(api_key_type: :read_info, path: '/sapi/v1/margin/maxBorrowable',
                        params: params, security_type: :user_data)
        end

=begin
        def status!(orderId: nil, originalClientOrderId: nil, recvWindow: nil, symbol: nil)
          raise Error.new(message: "symbol is required") if symbol.nil?
          raise Error.new(message: "either orderid or originalclientorderid " \
            "is required") if orderId.nil? && originalClientOrderId.nil?
          timestamp = Configuration.timestamp
          params = {
            orderId: orderId, origClientOrderId: originalClientOrderId, recvWindow: recvWindow,
            symbol: symbol, timestamp: timestamp
          }.delete_if { |key, value| value.nil? }
          Request.send!(api_key_type: :trading, path: "/api/v3/order",
                        params: params, security_type: :user_data)
        end
=end

        private

        def additional_required_create_keys(type:)
          case type
          when :limit
            [:price, :timeInForce].freeze
          when :stop_loss, :take_profit
            [:stopPrice].freeze
          when :stop_loss_limit, :take_profit_limit
            [:price, :stopPrice, :timeInForce].freeze
          when :limit_maker
            [:price].freeze
          else
            [].freeze
          end
        end

        def ensure_required_create_keys!(params:)
          keys = required_create_keys.dup.concat(additional_required_create_keys(type: params[:type]))
          missing_keys = keys.select { |key| params[key].nil? }
          raise Error.new(message: "required keys are missing: #{missing_keys.join(', ')}") unless missing_keys.empty?
        end

        def required_create_keys
          [:symbol, :side, :type, :quantity, :timestamp].freeze
        end
      end
    end
  end
end
