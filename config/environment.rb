require 'bundler'
Bundler.require

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'db/development.db')

# turn off debug messages to console
ActiveRecord::Base.logger = nil
require_all 'lib'
