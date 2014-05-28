# encoding: utf-8
require 'rubygems'

module Cobb
  class << self
    def log
      @log ||= NullLogger.new
    end
    
    attr_writer :log
    
    def settings
      @settings ||= Mash.new
    end

    def web_client
      WebClient.instance
    end
  end
end

require 'cobb/mash'
require 'cobb/gun'
require 'cobb/victim'
require 'cobb/order'
require 'cobb/web_client'
