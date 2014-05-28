# encoding: utf-8
require './samples/_base'

module Amazon
    class AuthorBooks < Cobb::Gun
        def mechanizm
            html.css('#mainResults .result').each do |row|
                next_to Book, row.at!('h3.title a').href
            end
        end
    end

    class Book < Cobb::Gun
        def mechanizm
            result(
                title: html.at!('h1#title #productTitle').text,
                author: html.at!('#byline .author a.contributorNameID').text,
                price: html.at!('#MediaMatrix .swatchElement.selected .a-color-price').text_
            )
        end
    end
end

if $0 == __FILE__
    url = 'http://www.amazon.com/Kurt-Vonnegut/e/B000APYE16/'
    victim = Amazon::AuthorBooks.fire(url)
    
    pp victim.next_orders
    
    victim2 = victim.next_orders.first.perform!
    
    pp victim2.data
end
