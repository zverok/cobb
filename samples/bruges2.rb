# encoding: utf-8
require 'rubygems'
require 'hashie'
require 'nokogiri'
require 'logger'

$:.unshift 'lib'
require 'cobb'

class Bruges < Cobb
    class Main < Weapon(:main)
        source 'http://visitbruges.be/'
        
        def fire
            noko.css('#navbar #dropdown a').each do |a| 
                next_to :category, a['href']
            end
        end
    end

    class Category < Weapon(:category)
        samples 'http://visitbruges.be/places/bars-cafes',
                'http://visitbruges.be/group/culture',
                'http://visitbruges.be/group/food'
                
        def fire
            reject! if noko.css('.location.info h2').empty?
            
            result(
                url: url,
                title: noko.css('.location.info h2').first.stext,
                description: noko.css('.location.info p').first.stext,
                path: noko.
                    css('.location.breadcrumb').text.
                    split(/\s*>\s*/)[1..-1].
                    map(&:strip)
            )
            
            subcategories = noko.css('div.subcat')
            if subcategories.empty?
                find_locations
            else
                find_subcategories(subcategories)
            end
        end
        
        private
        
        def find_locations
            noko.css('div.location').select{|div|
                div.search('div.title').first && more = div.search('a.more').first
            }.map{|div|
                next_to :location, div.search('a.more').first['href']
            }
        end
        
        def find_subcategories(subcategories)
            subcategories.each do |subcat|
                a = subcat.search('h3 a').first
                
                if a && a['href'].include?('/location/')
                    next_to :location, a['href']
                elsif a
                    next_to :category, a['href']
                end
            end
        end
    end

    class Location < Weapon(:location)
        samples 'http://visitbruges.be/location/bars-cafes/concertgebouwcafe4'
        
        def fire
            result(
                #category: source,
                
                url: url,
                
                title: noko.css('.location.detail .title').first.stext,
                description: noko.css('.location.detail .copy').first.stext,
                
                details: parse_dl(noko.css('.location.detail .detailedinfo dl'))
            )

            if map = noko.css('.copy #map').first
                pos = map.parent.search('script').first.text
                lat,lng = pos.scan(/pos = \[(\S+?),(\S+?)\]/).flatten
                
                result(
                    lat: lat,
                    lng: lng
                )
            end
        end
    end
end

require 'awesome_print'

#ap Bruges::Main.fire!
ap Bruges.birst!(:main, :category, :location)
