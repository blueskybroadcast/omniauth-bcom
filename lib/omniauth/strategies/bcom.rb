require 'omniauth-oauth2'
require 'httparty'

module OmniAuth
  module Strategies
    class Bcom < OmniAuth::Strategies::OAuth2
      option :client_options, {
        authorize_url: '/OAuth/StartOAuthLogin.aspx',
        event_code: '',
        site: 'https://b-comtest.mci-group.com',
        token_url: '/OAuth/API/GetAccessToken',
        user_info_url: '/OAuth/API/GetUserInfo'
      }

      option :app_options, { app_event_id: nil }

      uid { raw_info['id'] }

      name { 'bcom' }

      info do
        hsh = {
          first_name: raw_info['first_name'],
          last_name: raw_info['last_name'],
          email: raw_info['email'],
          event_codes: raw_info['participant_event_codes'],
          community_codes: raw_info['member_community_codes'],
          token: nil
        }
        hsh[:token] = access_token[:token] if access_token.present? && access_token[:token].present?
        hsh
      end

      extra do
        { raw_info: raw_info }
      end

      def creds
        self.access_token
      end

      def request_phase
        event_code = session['omniauth.params']['eventcode']
        event_code = 'EULAR2017' if Rails.env.development?
        params = { redirect_uri: callback_url, eventcode: event_code }
        redirect client.auth_code.authorize_url(params.merge(authorize_params))
      end

      def callback_phase
        @app_event = prepare_app_event

        unless request.params['code']
          record_log level: 'error', text: 'Invalid credentials', trigger_event_fail: true
          return fail!(:invalid_credentials)
        end

        query = {
          client_id: options[:client_id],
          redirect_uri: callback_url,
          client_secret: options[:client_secret],
          code: request.params['code']
        }
        query[:redirect_uri] = 'https://www.pathlms.com:3800/auth/bcom/callback?eventcode=EULAR2017' if Rails.env.development?

        response = fetch_data(token_url, query)

        self.access_token = {
          token: response['access_token'],
          token_expires: response['expires_in'],
          refresh_token: response['refresh_token']
        }

        self.env['omniauth.auth'] = auth_hash

        if @app_event
          self.env['omniauth.app_event_id'] = @app_event.id
          finalize_app_event
        end

        call_app!
      end

      def auth_hash
        hash = AuthHash.new(provider: name, uid: uid)
        hash.info = info
        hash.credentials = creds
        hash
      end

      def raw_info
        @raw_info ||= fetch_data(user_info_url)
      end

      private

      def record_log level:, text:, trigger_event_fail: false, exception_obj: nil
        Rails.logger.error "====== #{provider_name} [Fail? #{trigger_event_fail}]----------=========== #{text}"
        Rails.logger.error "====== #{provider_name} [EXCEPTION]----------=========== #{exception_obj.message}\n#{exception_obj.backtrace}\n" if exception_obj.present?
        if @app_event.present?
          @app_event.logs.create level: level, text: "#{provider_name} #{text}"
          @app_event.fail! if @app_event.in_progress? && trigger_event_fail
        end
        nil
      end

      def client_params
        {
          client_id: options[:client_id],
          redirect_uri: callback_url,
          response_type: 'code'
        }
      end

      def fetch_data(url, query = {}, options = {})
        default_options = { query: query }
        default_options[:headers] = { 'Authorization' => access_token[:token] } if access_token.present? && access_token[:token].present?
        default_options.merge!(options)

        record_log level: 'info', text: "#{provider_name} Request: GET #{url}"
        response = HTTParty.get(url, default_options)
        response_log = "#{provider_name} Response (code: #{response.code}): \n#{response.body}"

        if response.code == 200 && response.body != 'Bad Request'
          record_log level: 'info', text: response_log
          JSON.parse(response)
        elsif @app_event
          record_log level: 'error', text: response_log, trigger_event_fail: true
          {}
        end
      rescue Exception => e
        record_log level: 'error', text: "#{provider_name} Response failed due to internal error", trigger_event_fail: true, exception_obj: e
        {}
      end

      def finalize_app_event
        app_event_data = {
          user_info: {
            uid: uid,
            first_name: info['first_name'],
            last_name: info['last_name'],
            email: info['email']
          }
        }
        @app_event.update(raw_data: app_event_data)
      end

      def prepare_app_event
        Rails.logger.error("======----------=========== BCOM Request params: #{request.params}\nClient options: #{options.client_options}\nenv omniauth params: #{self.env['omniauth.params']}\nsession omniauth params: #{session['omniauth.params']}")
        slug = request.params['origin'] ? request.params['origin'].gsub(/\//, '') : request.params['slug']
        account = Account.find_by(slug: slug) || Provider.where(current: true, event_code: event_code).first&.account
        account&.app_events&.create(activity_type: 'sso')
      end

      def provider_name
        options.name.upcase
      end

      def token_url
        "#{options.client_options.site}#{options.client_options.token_url}"
      end

      def user_info_url
        "#{options.client_options.site}#{options.client_options.user_info_url}"
      end

      def event_code
        if !options.client_options&.event_code&.blank?
          options.client_options.event_code
        elsif !self.env&.[]('omniauth.params')&.[]('eventcode')&.blank?
          self.env['omniauth.params']['eventcode']
        else
          ''
        end
      end
    end
  end
end
