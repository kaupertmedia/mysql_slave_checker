#!/usr/bin/env ruby
require 'rubygems'
require 'mysql'
require 'active_support'

module Kauperts
	class Kauperts::MysqlSlaveChecker

		attr_reader :connection
		attr_reader :slave_status

		# 
		def initialize(attributes = {})
			attributes.symbolize_keys!
			attributes.each do |attr,value|
				instance_variable_set :"@#{attr}", value
			end
			get_slave_status
		end

		private 

		def establish_connection!
			# Mysql.new(host=nil, user=nil, passwd=nil, db=nil, port=nil, sock=nil, flag=nil) 
			@connection ||= Mysql.new(@host, @username, @password, nil, @port, @socket, @flag)
		end

		def get_slave_status
			establish_connection!
			rs = @connection.query('SHOW SLAVE STATUS')
			# nb: it's only one hash
			rs.each_hash { |h| @slave_status = h }
			@slave_status.each do |k, value|
				meth = Proc.new{converted_value(value)}
				self.class.send(:define_method, k.downcase, meth)
			end

			# Does simple type sanitizing for SHOW SLAVE STATUS output
			def converted_value(value)
				if value.downcase == 'yes' or value.downcase == 'no'
					value.downcase == 'yes'
				elsif value.blank?
					nil
				elsif /^\d+$/.match(value)
					value.to_i
				else
					value
				end
			end

		end

	end
end

options = {
	:host => ENV['MYSQL_HOST'],
	:socket => ENV['MYSQL_SOCKET'],
	:username => (ENV['MYSQL_USERNAME'] || 'root'),
	:password => ENV['MYSQL_PASSWORD']
}

checker = Kauperts::MysqlSlaveChecker.new(options)

# Do whatever you want to do with the status info you got now.
# Example:
puts "Seconds behind Master : #{checker.seconds_behind_master}"
puts "Slave IO running..... : #{checker.slave_io_running}"
puts "Slave SQL running.... : #{checker.slave_sql_running}"



