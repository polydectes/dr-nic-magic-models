print "Using native MySQL\n"
require 'logger'

ActiveRecord::Base.logger = Logger.new("debug.log")

db1 = "dr_nic_magic_models_unittest"

ActiveRecord::Base.establish_connection(
  :adapter  => "mysql",
  :username => "rich",
  :password => "rich",
  :encoding => "utf8",
  :host     => '127.0.0.1',
  :database => db1
)
