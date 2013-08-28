require 'omniauth-oauth2'
require 'httparty'

module OmniAuth
  module Strategies
    class Bcom < OmniAuth::Strategies::OAuth2
      option :client_options, {
        :site => 'https://b-comtest.mci-group.com',
        :authorize_url => '/OAuth/StartOAuthLogin.aspx',
        :token_url => '/OAuth/API/GetAccessToken',
        :user_info_url => '/OAuth/API/GetUserInfo'
      }

      uid { raw_info['id'] }

      name {'bcom'}

      info do
        {
          :first_name   => raw_info['first_name'],
          :last_name    => raw_info['last_name'],
          :email        => raw_info['email'],
          :event_codes  => raw_info['participant_event_codes']
        }
      end

      extra do
        { :raw_info => raw_info }
      end

      def creds
        self.access_token
      end

      def request_phase
        super
      end

      def callback_phase
        if request.params['code']
          parsed_response = JSON.parse(HTTParty.get(token_url,
            :query => {
              :client_id => options[:client_id],
              :redirect_uri => callback_url,
              :client_secret => options[:client_secret],
              :code => request.params['code']
            }
          ))

          self.access_token = {
            :token => parsed_response['access_token'],
            :token_expires => parsed_response['expires_in']
          }

          self.env['omniauth.auth'] = auth_hash
          call_app!
        else
          fail!(:invalid_credentials)
        end
      end

      def auth_hash
        hash = AuthHash.new(:provider => name, :uid => uid)
        hash.info = info
        hash.credentials = creds
        hash
      end

      def raw_info
        @raw_info ||= Omniauth::Api::Client.get_user_info(access_token[:token])
      end

      private

      def client_params
        {:client_id => options[:client_id], :redirect_uri => callback_url ,:response_type => "code"}
      end

      def token_url
        "#{options.client_options.site}#{options.client_options.token_url}"
      end

      def user_info_url
        "#{options.client_options.site}#{options.client_options.user_info_url}"
      end
    end
  end
end
