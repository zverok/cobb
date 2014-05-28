# encoding: utf-8
require './samples/_base'

class AmazonAuthorBooks < Cobb::Gun
    def mechanizm
        author = html.at!('#EntityName').text
        html.css('#mainResults .result').each do |row|
            result_row do
                result(
                    title: row.at!('h3.title a').text,
                    link: row.at!('h3.title a').href,
                    author: author
                )
            end
        end
    end
end

if $0 == __FILE__
    url = 'http://www.amazon.com/Kurt-Vonnegut/e/B000APYE16/'
    victim = AmazonAuthorBooks.fire(url)
    
    pp victim.results
end
