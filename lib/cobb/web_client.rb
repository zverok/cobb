require 'singleton'
require 'fileutils'
#require 'faraday'
require 'typhoeus'
require 'addressable/uri'

module Cobb
    class WebClient
        include Singleton
        
        DEFAULT_OPTIONS = {
            cache_base: 'tmp/cache',
            request_interval: 0.3,
            user_agent: 'Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.137 Safari/537.36'
        }
        
        def get(url)
            cached_get(url) || web_get(url)
        end
        
        def options
            Hashie::Mash.new(DEFAULT_OPTIONS)
        end
        
        private
        
        def cached_get(url)
            path = cached_path(url)
            File.exists?(path) ? File.read(path) : nil
        end
        
        def web_get(url)
            if @prev_request_time
                to_sleep = (@prev_request_time + options.request_interval) - Time.now
                sleep(to_sleep) if to_sleep > 0
            end

            #response = Faraday.get(url, 'User-Agent' => options.user_agent)
            response = Typhoeus.get(url, followlocation: true) #, 'User-Agent' => options.user_agent)
            @prev_request_time = Time.now

            put_to_cache(url, response.body)
            response.body
        end
        
        def cached_path(url)
            uri = Addressable::URI.parse(url)
            filename = [uri.path, uri.query].compact.join('?').gsub(/[?\/&]/, '-')
            filename = '_root_' if filename.empty?
            File.join(options.cache_base, uri.host, filename)
        end
        
        def put_to_cache(url, body)
            path = cached_path(url)
            FileUtils.mkdir_p File.dirname(path)
            File.write path, body
        end
    end
end
