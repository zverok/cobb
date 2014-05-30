# encoding: utf-8
module Cobb
  class FiringError < RuntimeError
    def FiringError.from(gun, url, exception)
      new("While firing #{gun.class}(#{url}): #{exception.class} - #{exception.message}").tap{|e|
        e.set_backtrace(exception.backtrace)
      }
    end
  end
  
  class TargetRejected < RuntimeError
  end
  
  class Gun
    class << self
      # settings DSL
      def targets(*src)
        options.targets.push(*src)
      end
      
      alias_method :target, :targets
      
      def initial?
        !targets.empty? && targets.all?{|s| !Cobb.gun?(s)}
      end
      
      def samples(*smpl)
        options.samples.push(*smpl)
      end
      
      alias_method :sample, :samples
      
      # usage
      def fire(url, context = {})
        new(context).fire(url)
      end
      
      def auto_fire(opts = {})
        options.targets && !options.targets.empty? or
          fail("#{inspect} has no explicitly defined targets")
        
        max = opts.delete(:max) ||
        make_targets(options.targets, opts[:context] || {}).
          select{|target| target.gun == self}.
          map(&:fire_at!)
      end
      
      def train
        options.samples.empty? and
          fail("#{inspect} has no explicitly defined training samples")
        
        options.samples.map{|s| fire(s)}
      end
      
      def web_client
        @web_client ||= WebClient.new
      end

      private
      
      DEFAULT_OPTIONS = {
        targets: [],
        samples: []
      }
      
      def options
        @options ||= Mash.new(DEFAULT_OPTIONS)
      end
      
      def make_targets(targets, context = {})
        targets.map{|src|
          case 
          when src.kind_of?(String)
            Target.new(self, src, context)
          when src.is_a?(Class) && src < Gun
            src.auto_fire.map(&:next_targets)
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
    rescue TargetRejected
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
      if !victim.result.empty?
        log.info "...#{inspect} result: #{victim.result.keys.join(', ')}"
      elsif !victim.results.empty?
        log.info "...#{inspect} results: #{victim.results.count} rows"
      end
      stats = victim.next_targets.group_by(&:gun).map{|g, ts| "#{g}: #{ts.count}"}
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
      Cobb.guarded_require 'nokogiri'
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
      @victim.merge_result!(hash)
    end
    
    def result_row(hash = nil, &block)
      @victim.row!(hash, &block)
    end
    
    def next_to(gun, url, context = {})
      Cobb.gun?(gun) or fail(ArgumentError, "You can't fire #{gun.inspect}!")
      
      @victim.next_target!(gun, url, context)
    end
    
    def repeat(url, context = {})
      next_to self.class, url, context
    end

    def reject!
      fail TargetRejected
    end
  end
end
