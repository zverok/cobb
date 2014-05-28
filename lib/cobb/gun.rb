# encoding: utf-8
module Cobb
  class Gun
    class << self
      # settings DSL
      def sources(*src)
        options.sources ||= []
        options.sources.push(*src)
      end
      
      alias_method :source, :sources
      
      # usage
      def fire(url, context = {})
        new(context).fire(url)
      end
      
      def auto_fire(opts = {})
        options.sources && !options.sources.empty? or
          fail("#{inspect} has no explicitly defined sources")
        
        max = opts.delete(:max) ||
        make_orders(options.sources, opts[:context] || {}).
          select{|order| order.gun == self}.
          map(&:perform!)
      end

      private
      
      def options
        @options ||= Mash.new
      end
      
      def make_orders(sources, context = {})
        sources.map{|src|
          case 
          when src.kind_of?(String)
            Order.new(self, src, context)
          when src.is_a?(Class) && src < Gun
            src.auto_fire.map(&:next_orders)
          else
            fail ArgumentError, "Don't know how to fire at #{src.inspect}"
          end
        }.flatten
      end
    end
    
    def initialize(context)
      @context = Mash.new(context)
    end
    
    def fire(url)
      @url = url
      @victim = Victim.new(self, url)
      @raw = Cobb.web_client.get(url)
      
      mechanizm
      
      @victim
    ensure
      @url = nil
      @victim = nil
      @raw = nil
    end
    
    protected
    
    def mechanizm
      fail NotImplementedError, '#mechanizm should be implemented in descendants'
    end
    
    private

    # parsing helpers DSL
    
    attr_reader :url, :raw
    attr_reader :context
    
    def html
      require 'nokogiri'
      require 'nokogiri/more'
      @html ||= Nokogiri::HTML(raw, url)
    end

    def result(hash)
      @victim.merge_data!(hash)
    end
    
    def result_row(hash = nil, &block)
      @victim.row!(hash, &block)
    end
    
    def next_to(gun, url, context = {})
      @victim.next_order!(gun, url, context)
    end
  end
end
