# encoding: utf-8
module Cobb
  class Vera
    def initialize(target)
      @target = target
      @guns = list_guns(target)
    end
    
    attr_reader :target
    
    NaughtProgressBar = Naught.build
    
    def birst!(opts = {})
      @progress_bar = if opts[:progress] 
        guarded_requre 'progress_bar'
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
      
      victims.select{|v| v.gun.class == target}
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
      !gun.sources || gun.sources.empty? and 
        fail(ArgumentError, "#{gun} has no sources defined")
        
      gun.sources.select{|src| src.is_a?(Class) && src < Gun}.map{|g| list_guns(g)}.flatten + [gun]
    end
  end
end
