# encoding: utf-8
require './samples/_base'

module Amazon
    class AuthorBooks < Cobb::Gun
        def mechanizm
            bio = html.at!('#artistCentralBio_officialFullBioContent').text
            
            html.css('#mainResults .result').each do |row|
                next_to Book, row.at!('h3.title a').href, author_bio: bio
            end
        end
    end

    class Book < Cobb::Gun
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
    url = 'http://www.amazon.com/Cats-Cradle-Novel-Kurt-Vonnegut/dp/038533348X/'
    victim = Amazon::Book.fire(url, author_bio: 'Sample author bio.')
    pp victim.data

    url = 'http://www.amazon.com/Kurt-Vonnegut/e/B000APYE16/'
    victim2 = Amazon::AuthorBooks.fire(url)
    pp victim2.next_orders.first
    victim3 = victim2.next_orders.first.perform!
    
    pp victim3.data
end
