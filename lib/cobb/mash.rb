# encoding: utf-8
require 'hashie'

module Cobb
  class Mash < Hashie::Mash
    def deep_update(other)
        super(other.reject{|k, v| v.nil?})
    end
    
    alias_method :update, :deep_update
    alias_method :merge!, :update    
  end
end
