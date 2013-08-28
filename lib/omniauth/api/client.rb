require 'httparty'

module Omniauth
  module Api
    class Client
      def self.get_participant_info(user_access_token, event_code)
        begin
          response = HTTParty.get(participant_info_url,
            :headers => { "Authorization" => user_access_token },
            :query => {
              :event_code => event_code
            }
          )

          JSON.parse(validate(response))
        rescue Exception => e
          raise BcomParticipantInfoError, e.message
        end
      end

      def self.get_user_info(user_access_token)
        begin
          response = HTTParty.get(user_info_url,
            :headers => { "Authorization" => user_access_token }
          )

          JSON.parse(validate(response))
        rescue Exception => e
          raise BcomUserInfoError, e.message
        end
      end

      private

      def self.participant_info_url
        "#{Omniauth.configuration.site}#{Omniauth.configuration.participant_info_url}"
      end

      def self.user_info_url
        "#{Omniauth.configuration.site}#{Omniauth.configuration.user_info_url}"
      end

      def self.validate(response)
        raise BcomRequestError, response.message if response.body == 'Bad Request'
        response
      end
    end
  end
end
