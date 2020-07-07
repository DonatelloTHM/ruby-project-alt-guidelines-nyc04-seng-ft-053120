require 'bundler'
Bundler.require

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'db/development.db')
<<<<<<< HEAD
=======

# turn off debug messages to console
>>>>>>> 00ec762248e11b6d621161c4952bdba2518f0819
ActiveRecord::Base.logger = nil
require_all 'lib'
