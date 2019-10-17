require 'faraday'
require 'faraday_middleware'

module Fastlane
  module Actions
    class GoyuyunAction < Action
      def self.run(params)
        UI.message("The goyuyun plugin is working!")

        api_host = "http://www.tgvia.com/apiv1/app/upload"
        api_token = params[:api_token]

        build_file = [
          params[:ipa],
          params[:apk]
        ].detect { |e| !e.to_s.empty? }

        if build_file.nil?
          UI.user_error!("You have to provide a build file")
        end

        UI.message("build_file: #{build_file}")

        password = params[:password]
        if password.nil?
          password = ""
        end

        update_description = params[:update_description]
        if update_description.nil?
          update_description = ""
        end

        install_type = params[:install_type]
        if install_type.nil?
          install_type = "1"
        end

        # start upload
        conn_options = {
          request: {
            timeout:       1000,
            open_timeout:  300
          }
        }

        goyuyun_client = Faraday.new(nil, conn_options) do |c|
          c.request(:multipart)
          c.request(:url_encoded)
          c.response(:json, content_type: /\bjson$/)
          c.adapter(:net_http)
        end

        params = {
            '_api_token' => api_token,
            'updateDescription' => update_description,
            'installType' => install_type,
            'file' => Faraday::UploadIO.new(build_file, 'application/octet-stream')
        }

        UI.message("Start upload #{build_file} to goyuyun...")

        response = goyuyun_client.post(api_host, params)
        info = response.body

        if info['code'] != 0
          UI.user_error!("GOYUYUN Plugin Error: #{info['message']}")
        end

        UI.success("Upload success. ")
        # UI.success "Upload success. Visit this URL to see: https://www.goyuyun.com/#{info['data']['appShortcutUrl']}"
      end

      def self.description
        "一键发布至买好云"
      end

      def self.authors
        ["vincentwu08"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "将您的App发布至买好云"
      end

      def self.available_options
        [
          # FastlaneCore::ConfigItem.new(key: :your_option,
          #                         env_name: "GOYUYUN_YOUR_OPTION",
          #                      description: "A description of your option",
          #                         optional: false,
          #                             type: String)
          FastlaneCore::ConfigItem.new(key: :api_token,
            env_name: "GOYUYUN_API_KEY",
         description: "api_token in your GOYUYUN account",
            optional: false,
                type: String),
          # FastlaneCore::ConfigItem.new(key: :user_key,
          #             env_name: "GOYUYUN_USER_KEY",
          #          description: "user_key in your GOYUYUN account",
          #             optional: false,
          #                 type: String),
          FastlaneCore::ConfigItem.new(key: :apk,
                           env_name: "GOYUYUN_APK",
                           description: "Path to your APK file",
                           default_value: Actions.lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH],
                           optional: true,
                           verify_block: proc do |value|
                             UI.user_error!("Couldn't find apk file at path '#{value}'") unless File.exist?(value)
                           end,
                           conflicting_options: [:ipa],
                           conflict_block: proc do |value|
                             UI.user_error!("You can't use 'apk' and '#{value.key}' options in one run")
                           end),
          FastlaneCore::ConfigItem.new(key: :ipa,
                           env_name: "GOYUYUN_IPA",
                           description: "Path to your IPA file. Optional if you use the _gym_ or _xcodebuild_ action. For Mac zip the .app. For Android provide path to .apk file",
                           default_value: Actions.lane_context[SharedValues::IPA_OUTPUT_PATH],
                           optional: true,
                           verify_block: proc do |value|
                             UI.user_error!("Couldn't find ipa file at path '#{value}'") unless File.exist?(value)
                           end,
                           conflicting_options: [:apk],
                           conflict_block: proc do |value|
                             UI.user_error!("You can't use 'ipa' and '#{value.key}' options in one run")
                           end),
          FastlaneCore::ConfigItem.new(key: :password,
                      env_name: "GOYUYUN_PASSWORD",
                   description: "set password to protect app",
                      optional: true,
                          type: String),
          FastlaneCore::ConfigItem.new(key: :update_description,
                      env_name: "GOYUYUN_UPDATE_DESCRIPTION",
                   description: "set update description for app",
                      optional: true,
                          type: String),
          FastlaneCore::ConfigItem.new(key: :install_type,
                      env_name: "GOYUYUN_INSTALL_TYPE",
                   description: "set install type for app (1=public, 2=password, 3=invite). Please set as a string",
                      optional: true,
                          type: String)
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        [:ios, :mac, :android].include?(platform)
        # true
      end
    end
  end
end
