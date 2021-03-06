require "json"
require "net/http"
require "base64"
require 'addressable/uri'

module Embulk
  module Filter
    class GoogleVisionApi < FilterPlugin
      class VisionClient
        ENDPOINT = "https://vision.googleapis.com/v1/images:annotate"
        def initialize(features:, google_api_key:)
          uri = URI.parse("#{ENDPOINT}?key=#{google_api_key}")
          @http = Net::HTTP.new(uri.host, uri.port)
          @http.use_ssl = true
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
          Embulk.logger.info("Google Cloud Vision API #{@features.map{ |h| h['type'] }.join(',')} processing.. => #{images}")
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
            response = Net::HTTP.get_response(Addressable::URI.parse(image_path))
            response.body
          else
            File.read(image_path)
          end
        rescue => e
          ""
        end
      end
    end
  end
end
