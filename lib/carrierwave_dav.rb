require 'rubygems'
require 'carrierwave'
require 'active_support'
require 'active_support/all'

require 'carrierwave_dav/file'
require 'carrierwave_dav/storage'

module CarrierWave
  module Dav

    mattr_accessor :dav_factory
    self.dav_factory = Net::DAV.method(:new)

  end
end