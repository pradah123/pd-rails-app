module Source
    class ObservationOrg
        module Repo
            AUTH_FILE_PATH = '/tmp/observation.org.auth'.freeze

            module_function
            
            def get_cached_auth_data()
                if !File.file?(AUTH_FILE_PATH)
                    return nil
                end

                return JSON.parse(File.read(AUTH_FILE_PATH))
            end

            def cache(auth_data)
                File.write(AUTH_FILE_PATH, auth_data.to_json)
            end

            def fetch_creator_name(creator_id)
              creator_name = nil
              if creator_id.blank?
                raise ArgumentError, 'Invalid user ID.'
                return creator_name
              end              
              response = HTTParty.get(
                'https://observation.org/users/%s' % [creator_id],
                # debug_output: $stdout
              )
              if response.success? && !response.body.nil?
                doc = Nokogiri::HTML(response.body)
                creator_name = doc&.at_css('div.app-content-title h1')&.text&.strip
              end
              
              return creator_name
            end
        end
    end
end
