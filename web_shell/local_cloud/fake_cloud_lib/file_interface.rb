module CloudConnect

  # Implements methods to retrieve files from the Cloud file storage
  # In VM mode, these methods simply access the disk.
  module FileStorage

    class << self

      # Retrieves information about the latest version of a file
      # @param [String] namespace a namespace for the file
      # @param [String] name the file name
      # @return [UserApis::Mdi::File::FileInfo] information about the file
      # @api private
      def get_file_information(namespace, name)
        raise NotImplementedError
      end

      # Retrieves file contents
      # @param [String] namespace a namespace for the file
      # @param [String] name the file name
      # @return [UserApis::Mdi::File] the last version of the 
      # @raise FileStorageException if an error occured
      def get_file_contents(namespace, name)
        raise NotImplementedError
      end

      def get_file_contents_by_md5(md5)
        raise NotImplementedError
      end

    end # class << self
  end

end
