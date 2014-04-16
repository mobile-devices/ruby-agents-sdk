module CloudConnectSDK

  # Implements methods to retrieve files from the Cloud file storage
  # In VM mode, these methods simply access the disk.
  module FileStorage

    class << self

      FILE_STORAGE_ROOT = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "file_storage"))

      # Retrieves information about the latest version of a file, or nil if no information is available.
      # @param [String] namespace a namespace for the file
      # @param [String] name the file name
      # @return [UserApis::Mdi::FileInfo] information about the file
      # @api private
      def get_file_information(namespace, name)
        begin
          data = File.read(file_path(namespace, name) + ".metadata.json")
        rescue Errno::ENOENT
          raise UserApis::Mdi::FileNotFoundError.new("File not found: #{namespace}/#{name}")
        end
        begin
          return UserApis::Mdi::FileInfo.new(JSON.parse(data, symbolize_names: true))
        rescue JSON::ParserError => e
          raise UserApis::Mdi::FileStorageError.new("Invalid metadata at #{namespace}/#{name}.metadata.json: #{e.message}")
        end
      end

      # Retrieves file contents
      # @param [String] namespace a namespace for the file
      # @param [String] name the file name
      # @return [String] the latest version of the file (binaray data)
      # @api private
      def get_file_contents(namespace, name)
        begin
          File.read(file_path(namespace, name))
        rescue Errno::ENOENT
          raise UserApis::Mdi::FileNotFoundError.new("File not found: #{namespace}/#{name}")
        end
      end

      # Retrieves a file
      # @param [String] namespace a namespace for the file
      # @param [String] name the file name
      # @return [UserApis::Mdi::CloudFile] the latest version of the file
      # @api private
      def get_file(namespace, name)
        file_info = get_file_information(namespace, name)
        raise UserApis::Mdi::FileNotFoundError.new("File not found: #{namespace}/#{name}") if file_info.nil?
        contents = get_file_contents(namespace, name)
        raise UserApis::Mdi::FileNotFoundError.new("File not found: #{namespace}/#{name}") if contents.nil?
        UserApis::Mdi::CloudFile.new(file_info.to_hash.merge({contents: contents}))
      end

      # todo(faucon_b): use md5 to have different versions of the same file

      # @api private
      # @param [UserApis::Mdi::CloudFile] file file to store
      # @note will overwrite any previous file stored with the same name/namespace
      def store_file(file)
        path = file_path(file.file_info.namespace, file.file_info.name)
        FileUtils.mkdir_p(File.dirname(path))
        FileUtils.rm(path) if File.exist?(path)
        FileUtils.rm(path + ".metadata.json") if File.exist?(path + ".metadata.json")
        File.write(path, file.contents)
        File.write(path + ".metadata.json", file.file_info.to_json)
      end

      def delete_file(namespace, name)
        FileUtils.rm(file_path(namespace, name))
        FileUtils.rm(file_path(namespace, name) + ".metadata.json")
      end

      def file_path(namespace, name)
        File.expand_path(File.join(FILE_STORAGE_ROOT, namespace, name))
      end

    end # class << self
  end

end
