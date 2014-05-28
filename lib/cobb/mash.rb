# encoding: utf-8
require 'hashie'

module Cobb
  class Mash < Hashie::Mash
    def deep_update(other)
       super(other.reject{|k, v| v.nil?})
    end
  end
end
