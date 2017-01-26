require_relative "google_vision_api/vision_client"

module Embulk
  module Filter
    class GoogleVisionApi < FilterPlugin
      Plugin.register_filter("google_vision_api", self)

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
        @image_path_key_name = task['image_path_key_name']
        @delay = task['delay']
        @image_num_per_request = task['image_num_per_request']
        @client = VisionClient.new(features: task['features'], google_api_key: task['google_api_key'])
      end

      def close
      end

      def add(page)
        record_groups = page.map { |record|
          Hash[in_schema.names.zip(record)]
        }.each_slice(@image_num_per_request).to_a

        record_groups.each do |records|
          requests = []
          images = records.map do |record|
            record[@image_path_key_name]
          end

          response = @client.request(images)
          records.each_with_index do |record, i|
            recognized = response.key?("error") ? response : response['responses'][i]
            Embulk.logger.warn "Error image => [#{record[@image_path_key_name]}] #{recognized}" if response.key?("error")
            page_builder.add(record.values + [recognized])
          end

          sleep @delay
        end
      end

      def finish
        page_builder.finish
      end
    end
  end
end
