# encoding: utf-8
module Cobb
  class FiringError < RuntimeError
    def FiringError.from(gun, url, exception)
      new("While firing #{gun.class}(#{url}): #{exception.class} - #{exception.message}").tap{|e|
        e.set_backtrace(exception.backtrace)
      }
    end
  end
  
  class SourceRejected < RuntimeError
  end
  
  class Gun
    class << self
      # settings DSL
      def sources(*src)
        options.sources ||= []
        options.sources.push(*src)
      end
      
      alias_method :source, :sources
      
      def initial?
        !sources.empty? && sources.all?{|s| !Cobb.gun?(s)}
      end
      
      def samples(*)
      end
      
      alias_method :sample, :samples
      
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
      
      def web_client
        @web_client ||= WebClient.new
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

      log.info "Firing #{inspect}"
      @raw = web_client.get(url)
      
      mechanizm

      log_victim(@victim)
      
      @victim
    rescue SourceRejected
      nil
    rescue => e
      fail FiringError.from(self, url, e)
    ensure
      @url = nil
      @victim = nil
      @raw = nil
    end
    
    def inspect
      if url
        "#<#{self.class.name}(#{url}) with #{context.to_hash.inspect}>"
      else
        "#<#{self.class.name} with #{context.to_hash.inspect}>"
      end
    end
    
    protected
    
    def mechanizm
      fail NotImplementedError, '#mechanizm should be implemented in descendants'
    end
    
    private
    
    def log
      Cobb.log
    end

    def log_victim(victim)
      log.info "...#{inspect} ready"
      if !victim.data.empty?
        log.info "...#{inspect} data: #{victim.data.keys.join(', ')}"
      elsif !victim.datum.empty?
        log.info "...#{inspect} datum: #{victim.datum.count} rows"
      end
      stats = victim.next_orders.group_by(&:gun).map{|g, os| "#{g}: #{os.count}"}
      unless stats.empty?
        log.info "...#{inspect} next urls: #{stats.join(', ')}"
      end
    end
    
    def web_client
      self.class.web_client
    end
    # parsing helpers DSL
    
    attr_reader :url, :raw
    attr_reader :context
    
    def html
      require 'nokogiri'
      require 'nokogiri/more'
      @html ||= Nokogiri::HTML(raw, url)
    end
    
    def json
      @json ||= from_json(raw)
    end
    
    def from_json(text)
      Kernel.const_defined?(:JSON) or
        fail("No JSON gem found. Pleas require json parsing gem you'd like")
      JSON.parse(text)
    end

    def result(hash)
      @victim.merge_data!(hash)
    end
    
    def result_row(hash = nil, &block)
      @victim.row!(hash, &block)
    end
    
    def next_to(gun, url, context = {})
      Cobb.gun?(gun) or fail(ArgumentError, "You can't fire #{gun.inspect}!")
      
      @victim.next_order!(gun, url, context)
    end
    
    def repeat(url, context = {})
      next_to self.class, url, context
    end

    def reject!
      fail SourceRejected
    end
  end
end
