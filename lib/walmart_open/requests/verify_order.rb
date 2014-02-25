require "walmart_open/commerce_request"
require "walmart_open/order_xml_builder"
require "walmart_open/order_results"
require "walmart_open/errors"
require "openssl"
require "base64"


module WalmartOpen
  module Requests
    class VerifyOrder < CommerceRequest
      attr_accessor :order

      def initialize(order)
        self.path = "orders/verify"
        @order = order
      end

      private

      # order_id: 32845878, <WalmartOpen::OrderError: {"errors"=>{"error"=>{"code"=>"10002", "message"=>"At this time only walmart seller items are supported. and WWW Server Name is ndc-wwwssl92.walmart.com and Current Timestamp is 2014-02-25 12:53:19.281"}}}>
      #{"orderId"=>"2677980185512", "partnerOrderId"=>"52", "items"=>{"item"=>{"itemId"=>"22660154", "quantity"=>"1", "itemPrice"=>"99.00"}}, "total"=>"111.66", "itemTotal"=>"99.00", "shipping"=>"0", "salesTax"=>"8.66", "productTax"=>"4.00", "surcharge"=>"0.00"}
=begin
      def parse_response(response)
        response
      end
=end

      def verify_response(response)
        if response.code == 400
          raise WalmartOpen::OrderError, response.parsed_response.inspect
        end
        super
      end

      def request_options(client)
        body = build_xsd
        signature = client.config.debug ? "FAKE_SIGNATURE" : sign(client.config.private_key, body)
        {
          headers: {
            "Authorization" => client.auth_token.authorization_header,
            "Content-Type" => "text/xml",
            "X-Walmart-Body-Signature" => signature
          },
          body: body
        }
      end

      def build_params(client)
        { disablesigv: true } if client.config.debug
      end

      def build_xsd
        OrderXMLBuilder.new(order).build
      end

      def sign(key, data)
        Base64.urlsafe_encode64(key.sign(OpenSSL::Digest::SHA256.new, data))
      end
    end
  end
end
