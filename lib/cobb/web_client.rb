require 'singleton'
require 'fileutils'
require 'faraday'
#require 'typhoeus'
require 'addressable/uri'

module Cobb
    class WebClient
        DEFAULT_OPTIONS = {
            cache_base: 'tmp/cache',
            request_interval: 0.3,
        }
        
        def initialize
            require 'typhoeus/adapters/faraday'
            @faraday = Faraday.new{|f|
                f.adapter :typhoeus
            }
        end
        
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

            response = @faraday.get(url)
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
