require "json"
require "net/http"
require "uri"
require "openssl"
require "base64"
require "pp"

module Embulk
  module Filter

    class GoogleVisionApi < FilterPlugin
      Plugin.register_filter("google_vision_api", self)
      ENDPOINT_PREFIX = "https://vision.googleapis.com/v1/images:annotate"

      def self.transaction(config, in_schema, &control)
        task = {
          "out_key_name" => config.param("out_key_name", :string),
          "image_path_key_name" => config.param("image_path_key_name", :string),
          "features" => config.param("features", :array),
          "delay" => config.param("delay", :integer, default: 0),
          "image_num_per_request" => config.param("image_num_per_request", :integer, default: 16),
          "google_api_key" => config.param("google_api_key", :string, default: ENV['GOOGLE_API_KEY']),
        }

        add_columns = [
          Column.new(nil, task["out_key_name"], :json)
        ]

        out_columns = in_schema + add_columns

        yield(task, out_columns)
      end

      def init
        @uri = URI.parse("#{ENDPOINT_PREFIX}?key=#{task['google_api_key']}")
        @http = Net::HTTP.new(@uri.host, @uri.port)
        @http.use_ssl = true
        @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        @post = Net::HTTP::Post.new(@uri.request_uri, initheader = {'Content-Type' =>'application/json'})
        @image_path_key_name = task['image_path_key_name']
        @out_key_name = task['out_key_name']
        @delay = task['delay']
        @image_num_per_request = task['image_num_per_request']
        @features = task['features']
      end

      def close
      end

      def add(page)
        record_groups = page.map { |record|
          Hash[in_schema.names.zip(record)]
        }.each_slice(@image_num_per_request).to_a

        record_groups.each do |records|
          requests = []
          records.each do |record|
            request = {
              image: {},
              features: @features
            }
            image_body = get_image_body(record)
            request[:image][:content] = Base64.encode64(image_body)
            requests << request
          end
          body = {
            requests: requests
          }
          @post.body = body.to_json
          Embulk.logger.debug "request body => #{@post.body}"

          response_hash = {}
          @http.start do |h|
            response = h.request(@post)
            response_hash = JSON.parse(response.body)
          end
          records.each_with_index do |record, i|
            recognized = response_hash['responses'][i]
            Embulk.logger.warn "Error image => [#{record[@image_path_key_name]}] #{recognized}" if recognized.key?("error")
            page_builder.add(record.values + [recognized])
          end

          sleep @delay
        end
      end

      def finish
        page_builder.finish
      end

      private
      def get_image_body(record)
        image_path = record[@image_path_key_name]
        if image_path =~ /https?\:\/\//
          Net::HTTP.get_response(URI.parse(image_path)).body rescue ""
        else
          File.read(image_path) rescue ""
        end
      end
    end
  end
end
