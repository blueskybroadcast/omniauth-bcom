require "omniauth-bcom/version"
require "omniauth/strategies/bcom"
require "omniauth/api/client"
require "omniauth/configuration"

module Omniauth

  class BcomCommunityMemberInfoError < StandardError; end
  class BcomParticipantInfoError < StandardError; end
  class BcomRequestError < StandardError; end
  class BcomUserInfoError < StandardError; end

  module Bcom

  end
end
