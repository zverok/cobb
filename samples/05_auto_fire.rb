# encoding: utf-8
require './samples/_base'

module Amazon
    class AuthorBooks < Cobb::Gun
        source 'http://www.amazon.com/Kurt-Vonnegut/e/B000APYE16/'
        
        def mechanizm
            bio = html.at!('#artistCentralBio_officialFullBioContent').text
            
            html.css('#mainResults .result').each do |row|
                next_to Book, row.at!('h3.title a').href, author_bio: bio
            end
        end
    end

    class Book < Cobb::Gun
        source AuthorBooks
        
        def mechanizm
            result(
                title: html.at!('h1#title #productTitle').text,
                author: html.at!('#byline .author a.contributorNameID').text,
                price: html.at!('#MediaMatrix .swatchElement.selected .a-color-price').text_,
                author_bio: context.author_bio
            )
        end
    end
end

if $0 == __FILE__
    victims = Amazon::AuthorBooks.auto_fire
    pp victims.map(&:next_orders).flatten
    
    victims2 = Amazon::Book.auto_fire
    pp victims2.map(&:data)

    victims3 = Amazon::Book.auto_fire(max: 1)
    pp victims3.map(&:data)
end
