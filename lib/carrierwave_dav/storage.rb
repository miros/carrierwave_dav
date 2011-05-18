require 'net/dav'

module CarrierWave
  module Dav
    class Storage < CarrierWave::Storage::Abstract

      def initialize(uploader, dav_path)
        super(uploader)
        @dav_path = dav_path
      end

      def store!(file)
        f = CarrierWave::Dav::File.new(uploader.store_path, @dav_path)
        f.write(file)
        f
      end

      def retrieve!(identifier)
        CarrierWave::Dav::File.new(uploader.store_path(identifier), @dav_path)
      end

    end
  end
end