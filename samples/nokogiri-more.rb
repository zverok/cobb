require 'rubygems'
require 'nokogiri'

# 1. bangs
Nokogiri::More::Config.bang_mode = :raise
Nokogiri::More::Config.bang_mode = :null
Nokogiri::More::Config.bang_mode = :log
Nokogiri::More::Config.logger = Logger.new(STDOUT)

# 2. questiongs


# 3. children groups

# 4. small services
