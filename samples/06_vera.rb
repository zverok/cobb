# encoding: utf-8
require './samples/_base'
require 'cobb/vera'

module Amazon
    class Vonnegut < Cobb::Gun
        target 'http://www.amazon.com/Kurt-Vonnegut/e/B000APYE16/'
        
        def mechanizm
            bio = html.at!('#artistCentralBio_officialFullBioContent').text
            
            html.css('#mainResults .result').each do |row|
                next_to Book, row.at!('h3.title a').href, author_bio: bio
            end
            
            html.at?('#pagn #pagnNextLink').tap{|a|
                next_to Vonnegut, a.href.gsub(' ', '%20') # WTF, really?..
            }
        end
    end

    class Book < Cobb::Gun
        target Vonnegut
        
        def mechanizm
            result(
                link: url,
                title: html.at!('h1#title #productTitle, #btAsinTitle').text,
                author: html.at?('#byline .author a.contributorNameID').text,
                price: html.at?('#MediaMatrix .swatchElement.selected .a-color-price').text_,
                author_bio: context.author_bio
            )
        end
    end
end

if $0 == __FILE__
    victims = Cobb::Vera.new(Amazon::Book).birst!(progress: true)
    pp victims.map(&:result)
end
