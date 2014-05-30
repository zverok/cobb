# encoding: utf-8
module Cobb
  class Vera
    def initialize(final)
      @final = final
      @guns = list_guns(final)
    end
    
    attr_reader :final
    
    NaughtProgressBar = Naught.build
    
    def birst!(opts = {})
      @progress_bar = if opts[:progress] 
        Cobb.guarded_require 'progress_bar'
        ProgressBar.new(1) 
      else
        NaughtProgressBar.new
      end
      
      @birst = []
      @ready_urls = []
      victims = guns.select(&:initial?).map(&:auto_fire).flatten
      victims.each{|v| postprocess_victim(v)}

      while !birst.empty?
        target = birst.shift
        new_victim = target.fire_at!
        
        if new_victim
          victims.push(new_victim)
          postprocess_victim(new_victim)
        end
        
        ready_urls.push(target.url)
        progress_bar.increment!
      end
      
      victims.select{|v| v.gun.class == final}
    end
    
    private
    
    attr_reader :guns, :birst, :ready_urls, :progress_bar
    
    def postprocess_victim(victim)
      targets = victim.next_targets.
        select{|t| guns.include?(t.gun)}.
        reject{|t| ready_urls.include?(t.url)}
      
      birst.push(*targets)
      birst.sort_by!{|t| guns.index(t.gun)}
      progress_bar.max = ready_urls.count + birst.size if ready_urls.count + birst.size > 0
    end
    
    def list_guns(gun)
      gun.targets.empty? and 
        fail(ArgumentError, "#{gun} has no targets defined")
        
      gun.targets.select{|t| Cobb.gun?(t)}.map{|g| list_guns(g)}.flatten + [gun]
    end
  end
end
