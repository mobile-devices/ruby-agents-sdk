require 'base64'

module CloudConnectSDK

  # Implements methods to retrieve files from the Cloud file storage
  # In VM mode, these methods simply access the disk.
  module FileStorage

    class << self

      FILE_STORAGE_ROOT = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "file_storage"))

      # Retrieves information about the latest version of a file, or nil if no information is available.
      # @param [String] namespace a namespace for the file
      # @param [String] name the file name
      # @param [String] account account of the asset which requested the file
      # @param [String] asset asset which requested the files
      # @return [UserApis::Mdi::FileInfo] information about the file
      # @raise [UserApis::Mdi::Unauthorized]
      # @api private
      def get_file_information(namespace, name, account, asset)
        file = get_file(namespace, name, account, asset)
        file.file_info
      end

      # Retrieves a file
      # @param [String] namespace a namespace for the file
      # @param [String] name the file name
      # @return [UserApis::Mdi::CloudFile] the latest version of the file
      # @raise [UserApis::Mdi::Unauthorized]
      # @api private
      def get_file(namespace, name, account, asset)
        path = file_path(namespace, name)
        raise UserApis::Mdi::FileNotFoundError.new("File not found: #{namespace}/#{name}") unless File.exist?(path)
        json = File.read(path)
        begin
          file = json_to_file(json)
        rescue JSON::ParserError, ArgumentError => e
          raise UserApis::Mdi::FileStorageError.new("Error when reading the file #{namespace}/#{name}: #{e}")
        end
        # check permissions, returns only the role used
        # by account or with role default
        read_access_role = file.file_info.roles.find do |role|
          role.name == "default" || role.accounts.include?(account)
        end
        if read_access_role.nil?
          # by asset
          read_access_role = file.file_info.roles.find do |role|
            role.assets.include?(asset)
          end
        end
        if read_access_role.nil? # neither account or asset has the authorization to read the file
          raise UserApis::Mdi::Unauthorized.new("Asset #{asset} of account #{account} is not authorized to read #{namespace}/#{name}")
        end
        file.file_info.roles = [read_access_role]
        file
      end

      # not available in Ragent
      def delete_file(namespace, name)
        FileUtils.rm(file_path(namespace, name))
      end

      # for internal use (also used by the TestsHelper)

      def json_to_file(json)
        parsed = JSON.parse(json, symbolize_names: true)
        roles = parsed[:roles].map do |role_name, role_def|
          UserApis::Mdi::ReadAccessRole.new(name: role_name.to_s, accounts: role_def[:accounts], assets: role_def[:assets])
        end
        file_info = UserApis::Mdi::FileInfo.new(name: parsed[:name],
                                                namespace: parsed[:namespace],
                                                md5: parsed[:md5],
                                                content_type: parsed[:content_type],
                                                roles: roles)
        UserApis::Mdi::CloudFile.new(file_info: file_info,
                                     contents: Base64.strict_decode64(parsed[:contents]),
                                     check_md5: false)
      end

      def file_to_json(file)
        encoded_contents = Base64.strict_encode64(file.contents)
        {
          name: file.file_info.name,
          namespace: file.file_info.namespace,
          md5: file.file_info.md5,
          content_type: file.file_info.content_type,
          contents: encoded_contents,
          roles: file.file_info.roles.each_with_object({}) do |role, h|
            h[role.name] ||= {}
            h[role.name][:accounts] = role.accounts
            h[role.name][:assets] = role.assets
          end
        }.to_json
      end

      def file_path(namespace, name)
        File.expand_path(File.join(FILE_STORAGE_ROOT, namespace, name))
      end

    end # class << self
  end

end