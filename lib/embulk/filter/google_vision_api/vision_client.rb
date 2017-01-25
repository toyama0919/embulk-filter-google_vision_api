require "json"
require "net/http"
require "uri"
require "openssl"
require "base64"

module Embulk
  module Filter
    class GoogleVisionApi < FilterPlugin
      class VisionClient
        def initialize(features, google_api_key)
          uri = URI.parse("https://vision.googleapis.com/v1/images:annotate?key=#{google_api_key}")
          @http = Net::HTTP.new(uri.host, uri.port)
          @http.use_ssl = true
          @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          @post = Net::HTTP::Post.new(uri.request_uri, initheader = {'Content-Type' =>'application/json'})
          @features = features
        end

        def request(images)
          @post.body = get_body(images).to_json
          Embulk.logger.debug "request body => #{@post.body}"

          @http.start do |h|
            response = h.request(@post)
            JSON.parse(response.body)
          end
        end

        private
        def get_body(images)
          {
            requests: get_requests(images)
          }
        end

        def get_requests(images)
          images.map do |image_path|
            get_request(image_path)
          end
        end

        def get_request(image_path)
          request = {
            image: Hash.new{|h,k| h[k] = {}},
            features: @features
          }
          if image_path =~ /gs\:\/\//
            request[:image][:source][:gcs_image_uri] = image_path
          else
            image_body = get_image_body(image_path)
            request[:image][:content] = Base64.encode64(image_body)
          end
          request
        end

        def get_image_body(image_path)
          if image_path =~ /https?\:\/\//
            Net::HTTP.get_response(URI.parse(image_path)).body rescue ""
          else
            File.read(image_path) rescue ""
          end
        end
      end
    end
  end
end
