module Types
    include Dry.Types()
end

module Source
    class ObservationOrg
        module Model
            class AuthData < Dry::Struct
                transform_keys(&:to_sym)

                attribute? :access_token, Types::String.optional
                attribute? :expires_in, Types::Coercible::Integer.optional
                attribute? :refresh_token, Types::String.optional            
                attribute? :expires_at, Types::Coercible::Integer.optional

                def valid?
                    return access_token_valid?
                end

                def access_token_valid?
                    return  expires_at != nil && 
                            access_token != nil && 
                            expires_at.to_i > Time.now.to_i
                end

                def refresh_token_valid?
                    return refresh_token != nil
                end
            end
        end
    end
end
