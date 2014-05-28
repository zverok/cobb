# encoding: utf-8
$:.unshift 'lib'
require 'cobb'

#Cobb.equip(:place) do
    #sample 'http://visitbruges.be/location/bars-cafes/concertgebouwcafe4'
    
    #run do
        ##category: source.except(:locations),

        #result :url, url
            
        #result :title, noko.css('.location.detail .title').first.stext
        #result :description, noko.css('.location.detail .copy').first.stext
        #result :details, parse_dl(noko.css('.location.detail .detailedinfo dl'))

        #if map = noko.css('.copy #map').first
            #pos = map.parent.search('script').first.text
            #lat,lng = pos.scan(/pos = \[(\S+?),(\S+?)\]/).flatten
            #result :lat, lat
            #result :lng, lng
        #end
    #end
#end

Cobb.equip(:category) do
    #sample  'http://visitbruges.be/places/bars-cafes',
            #'http://visitbruges.be/group/culture',
            #'http://visitbruges.be/group/food'
    
    run do
        reject! if noko.css('.location.info h2').empty?
        
        result :url, url
        result :title, noko.css('.location.info h2').first.stext
        result :path, noko.css('.location.breadcrumb').text.split(/\s*>\s*/)[1..-1].map(&:strip)
        result :description, noko.css('.location.info p').first.stext
        
        subcategories = noko.css('div.subcat')
        if subcategories.empty?
            noko.css('div.location').select{|div|
                div.search('div.title').first && more = div.search('a.more').first
            }.map{|div|
                next_to :place, div.search('a.more').first['href']
            }
        else
            subcategories.each do |subcat|
                a = subcat.search('h3 a').first
                if a && a['href'].include?('/location/')
                    next_to :place, a['href']
                elsif a
                    next_to :category, a['href']
                end
            end
        end
    end
end

Cobb.equip(:main) do
    source 'http://visitbruges.be/'
    
    run do
        noko.css('#navbar #dropdown a').each do |a| 
            next_to :category, a['href']
        end
    end
end

if __FILE__ == $0
    require 'awesome_print'
    #ap Cobb.fire(:category, sample: 'http://visitbruges.be/group/culture')
    #ap Cobb.fire(:place) #, sample: true)
    ap Cobb.equipment[:category].fire!('http://visitbruges.be/group/food').nexts
end
