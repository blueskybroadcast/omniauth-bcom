require "omniauth-bcom/version"
require "omniauth/strategies/bcom"
require "omniauth/api/client"
require "omniauth/configuration"

module Omniauth

  class BcomParticipantInfoError < StandardError; end
  class BcomRequestError < StandardError; end
  class BcomUserInfoError < StandardError; end

  module Bcom

  end
end
