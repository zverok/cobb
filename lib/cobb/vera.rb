# encoding: utf-8
require 'progress_bar'

module Cobb
  class Vera
    def initialize(target)
      @target = target
      @guns = list_guns(target)
    end
    
    attr_reader :target
    
    NaughtProgressBar = Naught.build{|cfg|
      cfg.mimic ProgressBar
    }
    
    def birst!(opts = {})
      @progress_bar = if opts[:progress] 
        ProgressBar.new(1) 
      else
        NaughtProgressBar.new
      end
      
      @birst = []
      @ready_urls = []
      victims = guns.select(&:initial?).map(&:auto_fire).flatten
      victims.each{|v| postprocess_victim(v)}

      while !birst.empty?
        order = birst.shift
        new_victim = order.perform!
        
        if new_victim
          victims.push(new_victim)
          postprocess_victim(new_victim)
        end
        
        ready_urls.push(order.url)
        progress_bar.increment!
      end
      
      victims.select{|v| v.gun.class == target}
    end
    
    private
    
    attr_reader :guns, :birst, :ready_urls, :progress_bar
    
    def postprocess_victim(victim)
      orders = victim.next_orders.
        select{|o| guns.include?(o.gun)}.
        reject{|o| ready_urls.include?(o.url)}
      
      birst.push(*orders)
      birst.sort_by!{|o| guns.index(o.gun)}
      progress_bar.max = ready_urls.count + birst.size if ready_urls.count + birst.size > 0
    end
    
    def list_guns(gun)
      gun.sources.select{|src| src.is_a?(Class) && src < Gun}.map{|g| list_guns(g)}.flatten + [gun]
    end
  end
end
