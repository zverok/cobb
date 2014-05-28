# encoding: utf-8
require './samples/_base'

class AmazonBook < Cobb::Gun
    def mechanizm
        result(
            title: html.at!('h1#title #productTitle').text,
            author: html.at!('#byline .author a.contributorNameID').text,
            price: html.at!('#MediaMatrix .swatchElement.selected .a-color-price').text_
        )
    end
end

if $0 == __FILE__
    url = 'http://www.amazon.com/Cats-Cradle-Novel-Kurt-Vonnegut/dp/038533348X/'
    victim = AmazonBook.fire(url)
    
    p victim.result
end
