module Omniauth
  class Configuration
    attr_accessor :authorize_url, :client_id, :community_member_info_url, :participant_info_url, :secret_key, :site, :token_url, :user_info_url

    def initialize
      @authorize_url = '/OAuth/StartOAuthLogin.aspx'
      @client_id = 'my_client_id'
      @community_member_info_url = '/OAuth/API/GetCommunityMemberInfo'
      @participant_info_url = '/OAuth/API/GetParticipantInfo'
      @secret_key = 'my_secret_key'
      @site = 'https://b-comtest.mci-group.com'
      @token_url = '/OAuth/API/GetAccessToken'
      @user_info_url = '/OAuth/API/GetUserInfo'
    end
  end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield configuration
  end
end
