require 'net/dav'

module CarrierWave
  module Dav

    class File
      def initialize(file_url, dav_path, connection = nil)
        @file_url = file_url
        @dav_path = append_trailing_slash(dav_path)

        uri = URI.parse(file_url)
        @file_path = uri.path

        @dav_host = file_url.gsub(@file_path, '')

        @connection = connection || CarrierWave::Dav.dav_factory.call(@dav_host)
        @created_dirs = []
      end

      attr_reader :connection, :file_path, :dav_host, :created_dirs, :file_url

      # это урл для ссылок на файлы
      def url
        "/" + file_url.gsub(@dav_path, '')
      end

      def path
        file_url
      end

      def read
        connection.get(file_path)
      end

      def write(file)
        mkpath(::File.dirname(file_path))
        connection.put_string(file_path, file.read)
      end

      def delete
        delete_path(file_path)
      end

      def size
        read.size
      end

      def mkpath(path)
        parts = path.split("/").reject(&:blank?)
        parts.inject("") do |current_path, part|
          current_path = ::File.join(current_path, part)
          create_path(current_path)
          current_path
        end
      end

      def create_path(path)
        path = append_trailing_slash(path)
        begin
          connection.mkdir(path)
          @created_dirs << path
        rescue EOFError
          # почему то ответ nginx приводит к этому эксепшену
          # папка тем не менее создаётся
          @created_dirs << path
        rescue Net::HTTPClientException => exc
          # если папка уже есть - плевать
        end
      end

      def destroy_created_dirs!(options = {})
        # Удаляем папки в порядке обратном созданию
        options[:min_depth] ||= 0
        dirs = @created_dirs.select{|dir| dir_depth(dir) >= options[:min_depth]}
        dirs.reverse.each {|folder| delete_path(folder)}
      end

      def content_type
        @content_type
      end

      def content_type=(new_content_type)
        @content_type = new_content_type
      end

      private

        def dir_depth(dir)
          dir.split("/").reject(&:blank?).count
        end

        def delete_path(path)
          connection.delete(path)
        rescue Exception
          # не обращаем внимания на ошибки при удалении
        end

        def append_trailing_slash(path)
          path.last == "/" ? path : path + "/"
        end

    end

  end
end
