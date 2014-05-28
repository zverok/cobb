# encoding: utf-8
module Cobb
  class Victim
    def initialize(gun, url)
      @data = Hashie::Mash.new
    end
    
    attr_reader :data
  end
end
