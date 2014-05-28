# encoding: utf-8
require 'rubygems'
require 'naught'

module Cobb
  class << self
    NaughtLogger = Naught.build{|cfg|
        cfg.mimic Logger
    }

    def log
      @log ||= NaughtLogger.new
    end
    
    def gun?(object)
      object.is_a?(Class) && object < Gun
    end
    
    attr_writer :log
    
    def settings
      @settings ||= Mash.new
    end
    
    def guarded_requre(gem)
      require gem
    rescue LoadError
      fail "Can't require optional #{gem}, possibly you should add it to your Gemfile to use"
    end
  end
end

require 'cobb/mash'
require 'cobb/gun'
require 'cobb/victim'
require 'cobb/order'
require 'cobb/web_client'
