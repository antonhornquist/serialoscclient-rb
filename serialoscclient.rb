require 'set'
require 'osc-ruby'

#
# Dependancy support
#
class Object
	# dependancy support
	@@dependants_dictionary = Hash.new

	def dependants
		@@dependants_dictionary[self] or Set.new
	end

	def changed(what, *more_args)
		if @@dependants_dictionary[self]
			@@dependants_dictionary[self].dup.each do |item|
				item.update(self, what, *more_args)
			end
		end
	end

	def add_dependant(dependant)
		the_dependants = @@dependants_dictionary[self]
		if the_dependants
			the_dependants.add(dependant)
		else
			the_dependants = Set.new
			the_dependants.add(dependant)
			@@dependants_dictionary[self] = the_dependants
		end
	end

	def remove_dependant(dependant)
		the_dependants = @@dependants_dictionary[self]
		if the_dependants
			the_dependants.delete(dependant)
			if the_dependants.size == 0
				@@dependants_dictionary.delete(self)
			end
		end
	end

	def release
		release_dependants
	end

	def release_dependants
		@@dependants_dictionary.delete(self)
	end

	def update(the_changed, the_changer, *more_args)
	end
end

#
# ProcList:
# Based on SuperCollider's FunctionList Class
#
class ProcList
	attr_accessor :array

	def initialize(*procs)
		@array = procs
	end

	def add_proc(*procs, &block)
		@array = @array + procs
		@array << block if block_given?
		self
	end

	def remove_proc(a_proc)
		@array.delete a_proc
		array.size < 2 ? array[0] : self
	end

	def call(*args)
		@array.collect do |a_proc|
			a_proc.call(*args)
		end
	end
	
	alias :add_func :add_proc
	alias :remove_func :remove_proc # TODO
	alias :update :call
end

#
# NilClass extension
# ProcList support
#
class NilClass
	def add_proc(*procs, &block)
		procs = procs + [block] if block_given?
		if procs.size <= 1
			procs[0]
		else
			ProcList.new(*procs)
		end
	end

	def remove_proc(a_proc)
		self
	end

	alias :add_func :add_proc
	alias :remove_func :remove_proc # TODO
end

#
# Proc extension
# ProcList support
#
class Proc
	def add_proc(*procs, &block)
		arr = [self] + procs
		arr << block if block_given?
		ProcList.new(*arr)
	end

	def remove_proc(a_proc)
		nil
	end

	alias :add_func :add_proc
	alias :remove_func :remove_proc # TODO
	alias :update :call
end

class SerialOSCDevice
	attr_reader :type, :id, :port
	attr_accessor :client

	def initialize(type, id, port)
		@type = type
		@id = id
		@port = port
	end

	def self.connect
		@@default.connect if @@default
	end

	def self.disconnect
		@@default.disconnect if @@default
	end

	def client=(client)
		@client = client
	end

	def pr_send_msg(address, *args)
		message = OSC::Message.new(pr_get_prefixed_address(address), *args)
		client = OSC::Client.new(SerialOSC::SERIALOSCD_HOST, @port)
		client.send(message)
	end

	def pr_get_prefixed_address(address)
		"/" + @id.to_s + address.to_s
	end

	def remove
		disconnect
		SerialOSCClient.devices.delete(self)
		SerialOSCClientNotification.device_detached(self)
	end

	def connect
		SerialOSCClient.connect(self)
	end

	def disconnect
		SerialOSCClient.disconnect(self)
	end

	def is_connected?
		SerialOSCClient.connected_devices.include? self
	end
end

class SerialOSCGrid < SerialOSCDevice
	attr_reader :rotation

	@@default = nil

	def self.all
		SerialOSCClient.devices.reject do |device|
			SerialOSCClient.pr_is_enc_type(device.type)
		end
	end

	def self.default
		@@default
	end

	def self.default=(grid)
		prev_default = @@default
		if not grid
			@@default = nil
		else
			if SerialOSCClient.devices.include? grid
				if grid.respond_to? :led_set
					@@default = grid
				else
					raise("Not a grid: %s" % [grid])
				end
			else
				raise("%s is not in SerialOSCClient devices list" % [grid])
			end
		end
		if @@default != prev_default
			changed(:default, default)
		end
	end

	def self.unrouted
		all.select {|grid| not grid.client }
	end

	def self.connected
		all.select {|grid| grid.is_connected? }
	end

	def initialize(type, id, port, rotation)
		super(type, id, port)
		@rotation = rotation
	end

	def self.clear_leds
		@@default.clear_leds if @@default
	end

	def self.activate_tilt
		@@default.activate_tilt if @@default
	end

	def self.deactivate_tilt
		@@default.deactivate_tilt if @@default
	end

	def self.led_set(x, y, state)
		@@default.led_set(x, y, state) if @@default
	end

	def self.led_all(state)
		@@default.led_all(state) if @@default
	end

	def self.led_map(x_offset, y_offset, bitmasks)
		@@default.led_map(x_offset, y_offset, bitmasks) if @@default
	end

	def self.led_row(x_offset, y, bitmasks)
		@@default.led_row(x_offset, y, bitmasks) if @@default
	end

	def self.led_col(x, y_offset, bitmasks)
		@@default.led_col(x, y_offset, bitmasks) if @@default
	end

	def self.led_intensity(i)
		@@default.led_intensity(i) if @@default
	end

	def self.led_level_set(x, y, l)
		@@default.led_level_set(x, y, l) if @@default
	end

	def self.led_level_all(l)
		@@default.led_level_all(l) if @@default
	end

	def self.led_level_map(x_offset, y_offset, levels)
		@@default.led_level_set(x_offset, y_offset, levels) if @@default
	end

	def self.led_level_row(x_offset, y, levels)
		@@default.led_level_row(x_offset, y, levels) if @@default
	end

	def self.led_level_col(x, y_offset, levels)
		@@default.led_level_col(x, y_offset, levels) if @@default
	end

	def self.tilt_set(n, state)
		@@default.tilt_set(n, state) if @@default
	end

	def self.num_buttons
		@@default.num_buttons if @@default
	end

	def self.num_cols
		@@default.num_cols if @@default
	end

	def self.num_rows
		@@default.num_rows if @@default
	end

	def self.rotation
		@@default.rotation if @@default
	end

	def self.rotation=(rotation)
		@@default.rotation=(rotation) if @@default
	end

	def clear_leds
		led_all(0)
	end

	def activate_tilt(n)
		tilt_set(n, true)
	end

	def deactivate_tilt(n)
		tilt_set(n, false)
	end

	def led_set(x, y, state)
		pr_send_msg(:'/grid/led/set', x.to_i, y.to_i, state.to_i)
	end

	def led_all(state)
		pr_send_msg(:'/grid/led/all', state.to_i)
	end

	def led_map(x_offset, y_offset, bitmasks)
		pr_send_msg(:'/grid/led/map', x_offset.to_i, y_offset.to_i, *bitmasks)
	end

	def led_row(x_offset, y, bitmasks)
		pr_send_msg(:'/grid/led/row', x_offset.to_i, yto_i, *bitmasks)
	end

	def led_col(x, y_offset, bitmasks)
		pr_send_msg(:'/grid/led/row', x.to_i, y_offset.to_i, *bitmasks)
	end

	def led_intensity(i)
		pr_send_msg(:'/grid/led/intensity', i.to_i)
	end

	def led_level_set(x, y, l)
		pr_send_msg(:'/grid/led/level/set', x.to_i, y.to_i, l.to_i)
	end

	def led_level_all(l)
		pr_send_msg(:'/grid/led/level/all', l.to_i)
	end

	def led_level_map(x_offset, y_offset, levels)
		pr_send_msg(:'/grid/led/level/map', x_offset.to_i, y_offset.to_i, *levels)
	end

	def led_level_row(x_offset, y, levels)
		pr_send_msg(:'/grid/led/level/row', x_offset.to_i, y.to_i, *levels)
	end

	def led_level_col(x, y_offset, levels)
		pr_send_msg(:'/grid/led/level/col', x.to_i, y_offset.to_i, *levels)
	end

	def tilt_set(n, state)
		pr_send_msg(:'/tilt/set', n.to_i, state.to_i)
	end

	def num_buttons
		num_rows * num_cols
	end

	def num_cols
		case
		when [0, 180].include?(@rotation) then pr_device_num_cols_from_type
		when [90, 270].include?(@rotation) then pr_device_num_rows_from_type
		end
	end

	def num_rows
		case
		when [0, 180].include?(@rotation) then pr_device_num_rows_from_type
		when [90, 270].include?(@rotation) then pr_device_num_cols_from_type
		end
	end

	def rotation=(degrees)
		SerialOSC.change_device_rotation(@port, degrees)
		@rotation = degrees
		changed(:rotation, degrees)
		@client.warn_if_grid_does_not_match_spec if @client
	end

	def pr_device_num_cols_from_type
		case type
		when :'monome 64' then 8
		when :'monome 40h' then 8
		when :'monome 128' then 16
		when :'monome 256' then 16
		end
	end

	def pr_device_num_rows_from_type
		case type
		when :'monome 64' then 8
		when :'monome 40h' then 8
		when :'monome 128' then 8
		when :'monome 256' then 16
		end
	end

	def unroute
		@client.unroute_grid if @client
	end

	def to_s
		"SerialOSCGrid (#{@type}, #{@id}, #{@port}, #{@rotation})"
	end
end

class SerialOSCEnc < SerialOSCDevice
	@@default = nil

	def self.all
		SerialOSCClient.devices.select do |device|
			SerialOSCClient.pr_is_enc_type(device.type)
		end
	end

	def self.default
		@@default
	end

	def self.default=(enc)
		prev_default = @@default
		if not enc
			@@default = nil
		else
			if SerialOSCClient.devices.include? enc
				if enc.respond_to? :ring_set
					@@default = enc
				else
					raise("Not a enc: %s" % [enc])
				end
			else
				raise("%s is not in SerialOSCClient devices list" % [enc])
			end
		end
		if @@default != prev_default
			changed(:default, default)
		end
	end

	def self.unrouted
		all.select {|enc| not enc.client }
	end

	def self.connected
		all.select {|enc| enc.is_connected? }
	end

	def self.clear_rings
		@@default.clear_rings if @@default
	end

	def self.ring_set(n, x, level)
		@@default.ring_set(n, x, level) if @@default
	end

	def self.ring_all(n, level)
		@@default.ring_all(n, level) if @@default
	end

	def self.ring_map(n, levels)
		@@default.ring_map(n, levels) if @@default
	end

	def self.ring_range(n, x1, x2, level)
		@@default.ring_range(n, x1, x2, level) if @@default
	end

	def self.num_encs
		@@default.num_encs if @@default
	end

	def clear_rings
		4.times { |n| ring_all(n, 0) }
	end

	def ring_set(n, x, level)
		pr_send_msg(:'/ring/set', n.to_i, x.to_i, level.to_i)
	end

	def ring_all(n, level)
		pr_send_msg(:'/ring/all', n.to_i, level.to_i)
	end

	def ring_map(n, levels)
		pr_send_msg(:'/ring/map', n.to_i, *levels)
	end

	def ring_range(n, x1, x2, level)
		pr_send_msg(:'/ring/range', n.to_i, x1.to_i, x2.to_i, level)
	end

	def num_encs
		case type
		when :'monome arc 2' then 2
		when :'monome arc 4' then 4
		end
	end

	def unroute
		@client.unroute_enc if @client
	end

	def to_s
		"SerialOSCEnc (#{@type}, #{@id}, #{@port})"
	end
end

class AbstractResponder
	attr_reader :func, :device
	attr_accessor :permanent
	def initialize(func, device)
		@permanent = false
		@func = func
		@device = device
	end

	# TODO: make helper methods for matching device
	def matches_device_constraint?(device, default_device)
		@device === device or (@device === default_device and device == :default) # TODO: extend, to cover for :client => self and other scenarios
	end

	def free
		@@all.remove(self)
		SerialOSCClient.remove_recv_serialoscfunc(@serialoscfunc)
	end

	def self.free_all
		@@all.dup.each { |func| func.free }
	end
end

class EncDeltaFunc < AbstractResponder
	attr_reader :n, :delta

	@@all = []

	def self.all
		@@all
	end

	def initialize(func, n=nil, delta=nil, device=nil)
		super(func, device)
		@n = n
		@delta = delta
		@serialoscfunc = lambda do |type, args, time, device|
			if type == :'/enc/delta'
				n = args[0]
				delta = args[1]
				# TODO: test constraints
				if matches_device_constraint?(device, SerialOSCEnc.default) and matches_responder_specific_constraint?(n, delta)
					@func.call(n, delta, time, device) if @func
				end
			end
		end
		SerialOSCClient.add_recv_serialoscfunc(@serialoscfunc)
		@@all << self
	end

	def matches_responder_specific_constraint?(n, delta)
		((@n == nil) or (@n == n)) and ((@delta == nil) or (@delta == delta))
	end
end

class EncKeyFunc < AbstractResponder
	attr_reader :n, :state

	@@all = []

	def self.all
		@@all
	end

	def initialize(func, n=nil, state=nil, device=nil)
		super(func, device)
		@n = n
		@state = state
		@serialoscfunc = lambda do |type, args, time, device|
			if type == :'/enc/key'
				n = args[0]
				state = args[1]
				# TODO: test constraints
				if matches_device_constraint?(device, SerialOSCEnc.default) and matches_responder_specific_constraint?(n, state)
					@func.call(n, state, time, device) if @func
				end
			end
		end
		SerialOSCClient.add_recv_serialoscfunc(@serialoscfunc)
		@@all << self
	end

	def matches_responder_specific_constraint?(n, state)
		((@n == nil) or (@n == n)) and ((@state == nil) or (@state == state))
	end
end

class GridKeyFunc < AbstractResponder
	attr_reader :x, :y, :state

	@@all = []

	def self.all
		@@all
	end

	def initialize(func, x=nil, y=nil, state=nil, device=nil)
		super(func, device)
		@x = x
		@y = y
		@state = state
		@serialoscfunc = lambda do |type, args, time, device|
			if type == :'/grid/key'
				x = args[0]
				y = args[1]
				state = args[2]
				# TODO: test constraints
				if matches_device_constraint?(device, SerialOSCGrid.default) and matches_responder_specific_constraint?(x, y, state)
					@func.call(x, y, state, time, device) if @func
				end
			end
		end
		SerialOSCClient.add_recv_serialoscfunc(@serialoscfunc)
		@@all << self
	end

	def matches_responder_specific_constraint?(x, y, state)
		((@x == nil) or (@x == x)) and ((@y == nil) or (@y == y)) and ((@state == nil) or (@state == state))
	end

	def self.press(func, x, y, device)
		self.new(func, x, y, true, device)
	end

	def self.release(func, x, y, device)
		self.new(func, x, y, false, device)
	end
end

class TiltFunc < AbstractResponder
	attr_reader :n, :x, :y, :z

	@@all = []

	def self.all
		@@all
	end

	def initialize(func, n=nil, x=nil, y=nil, z=nil, device=nil)
		super(func, device)
		@n = n
		@x = x
		@y = y
		@z = z
		@serialoscfunc = lambda do |type, args, time, device|
			if type == :'/tilt'
				n = args[0]
				x = args[1]
				y = args[2]
				z = args[3]
				# TODO: test constraints
				if matches_device_constraint?(device, SerialOSCGrid.default) and matches_responder_specific_constraint?(n, x, y, z)
					@func.call(n, x, y, z, time, device) if @func
				end
			end
		end
		SerialOSCClient.add_recv_serialoscfunc(@serialoscfunc)
		@@all << self
	end

	def matches_responder_specific_constraint?(n, x, y, z)
		((@n == nil) or (@n == n)) and ((@x == nil) or (@x == x)) and ((@y == nil) or (@y == y)) and ((@z == nil) or (@z == z))
	end
end

class SerialOSC
	DEFAULT_TIMEOUT = 0.05
	SERIALOSCD_HOST = "127.0.0.1"
	SERIALOSCD_PORT = 57120 # 12002 # TODO use 57120 to test with SuperCollider mock server
	OSCSERVER_HOST = "127.0.0.1" # TODO: naming
	OSCSERVER_PORT = 8001 # TODO: naming

	@@osc_server_initialized=false
	@@registered_osc_recv_func=nil
	@@trace=false
	@@serialosc_device_response_handler=nil
	@@sys_info_response_handler=nil
	@@device_added_func=nil
	@@device_removed_func=nil
	@@is_tracking_connected_devices_changes=false
	@@device_list_semaphore = Mutex.new
	@@device_info_semaphore = Mutex.new

	def self.is_tracking_connected_devices_changes
		@@is_tracking_connected_devices_changes
	end

	def self.registered_osc_recv_func 
		@@registered_osc_recv_func 
	end

	def self.registered_osc_recv_func=(func)
		@@registered_osc_recv_func=func
	end

	def self.trace(on=true)
		@@trace=on
	end

	# TODO: this has to be run prior to request_list_of_devices_async or start_tracking_connected_devices_changes if using SerialOSC solely
	def self.init_osc_server(completion_func=nil) # TODO: ruby only
		if not @@osc_server_initialized
			pr_trace_output( "@@osc_server=Server.new(%i)" % [OSCSERVER_PORT] )
			@@osc_server = OSC::Server.new(OSCSERVER_PORT)

			pr_trace_output( "@@osc_server.add_method '/serialosc/device'" )
			@@osc_server.add_method '/serialosc/device' do |message|
				msg = message.to_a
				id = msg[0]
				type = msg[1]
				receive_port = msg[2].to_i
				device = {
					:id => id,
					:type => type,
					:receive_port => receive_port
				}

				pr_trace_output( "received: /serialosc/device %s %s %i" % [id, type, receive_port] )
				@@serialosc_device_response_handler.call(device) if @@serialosc_device_response_handler
			end

			pr_trace_output( "@@osc_server.add_method '/serialosc/add'" )
			@@osc_server.add_method '/serialosc/add' do |message|
				msg = message.to_a
				id = msg[0]
				pr_trace_output( "received: /serialosc/add %s" % [id] )
				@@device_added_func.call(id) if @@device_added_func
			end

			pr_trace_output( "@@osc_server.add_method '/serialosc/remove'" )
			@@osc_server.add_method '/serialosc/remove' do |message|
				msg = message.to_a
				id = msg[0]
				pr_trace_output( "received: /serialosc/remove %s" % [id] )
				@@device_removed_func.call(id) if @@device_removed_func
			end

			['port', 'host', 'id', 'prefix', 'rotation', 'size'].map do |attribute|
				pr_trace_output( "@@osc_server.add_method '/sys/#{attribute}'" )
				@@osc_server.add_method "/sys/#{attribute}" do |message|
					pr_trace_output( "received: '/sys/#{attribute} %s'" % [message.to_a.join(" ")] )
					@@sys_info_response_handler.call(attribute, message) if @@sys_info_response_handler
				end
			end

			[
				/\/.*\/grid\/key/,
				/\/.*\/tilt/,
				/\/.*\/enc\/delta/,
				/\/.*\/enc\/key/,
				/\/.*\/press/
			].map do |method|
				pr_trace_output( "@@osc_server.add_method '#{method}'" )
				@@osc_server.add_method(method) do |message|
					pr_trace_output( "received: '#{method} %s'" % [message.to_a.join(" ")] )
					@@registered_osc_recv_func.call(message, (message.time or Time.now)) if @@registered_osc_recv_func
				end
			end

			@@osc_server_pid = Thread.new do
				pr_trace_output( "@@osc_server.run" )
				@@osc_server.run
			end

			# Thread.new do # TODO
			sleep 0.05
			@@osc_server_initialized = true
			#   completion_func.call if completion_func
			# end
		end
	end

	def self.request_list_of_devices_async(timeout=nil)
		Thread.new do
			list_of_devices = nil

			@@device_list_semaphore.synchronize do
				list_of_devices = Array.new

				@@serialosc_device_response_handler = lambda { |device| list_of_devices << device }
				pr_trace_output( "started listening to serialosc device list OSC responses" )

				pr_send_message(
					SERIALOSCD_HOST,
					SERIALOSCD_PORT,
					OSC::Message.new("/serialosc/list", OSCSERVER_HOST, OSCSERVER_PORT)
				)

				sleeptime = (timeout or DEFAULT_TIMEOUT)
				pr_trace_output( "waiting %s seconds for serialosc device list OSC reponses..." % [sleeptime] )
				sleep sleeptime

				@@serialosc_device_response_handler = nil
				pr_trace_output( "stopped listening to serialosc device list OSC responses" )
			end

			yield list_of_devices if block_given?
		end
	end

	def self.request_information_about_device_async(device_receive_port, timeout=nil)
		Thread.new do
			device_info = nil

			@@device_info_semaphore.synchronize do
				device_info = {}

				@@sys_info_response_handler = lambda do |attribute, message|
					msg = message.to_a
					case attribute
					when 'port' then device_info[:destination_port] = msg[0].to_i
					when 'host' then device_info[:destination_host] = msg[0]
					when 'id' then device_info[:id] = msg[0]
					when 'prefix' then device_info[:prefix] = msg[0]
					when 'rotation' then device_info[:rotation] = msg[0].to_i
					when 'size' then device_info[:size] = { :x => msg[0].to_i, :y => msg[1].to_i }
					end
				end

				pr_trace_output( "started listening to serialosc device info OSC responses" )

				pr_send_message(
					SERIALOSCD_HOST,
					device_receive_port,
					OSC::Message.new("/sys/info", OSCSERVER_HOST, OSCSERVER_PORT)
				)

				sleeptime = (timeout or DEFAULT_TIMEOUT)
				pr_trace_output( "waiting %d seconds for device info OSC reponses..." % [sleeptime] )
				sleep sleeptime

				@@sys_info_response_handler = nil
				pr_trace_output( "stopped listening to serialosc device info OSC responses" )
			end

			yield device_info if block_given?
		end
	end

	def self.start_tracking_connected_devices_changes(added_func, removed_func)
		raise "Already tracking serialosc device changes." if @@is_tracking_connected_devices_changes
		@@is_tracking_connected_devices_changes = true
		@@device_added_func = lambda do |id|
			added_func.call(id)
			pr_send_request_next_device_change_msg
		end
		@@device_removed_func = lambda do |id|
			removed_func.call(id)
			pr_send_request_next_device_change_msg
		end
		pr_trace_output( "started listening to serialosc device add / remove OSC messages" )
		pr_send_request_next_device_change_msg
	end

	def self.stop_tracking_connected_devices_changes
		raise "Not listening for serialosc responses." unless @@is_tracking_connected_devices_changes
		@@is_tracking_connected_devices_changes = false
		@@device_added_func = nil
		@@device_removed_func = nil
		pr_trace_output( "stopped listening to serialosc device add / remove OSC messages" )
	end

	def self.change_device_destination_port(device_receive_port, device_destination_port)
		pr_send_message(
			SERIALOSCD_HOST,
			device_receive_port,
			OSC::Message.new("/sys/port", device_destination_port)
		)
	end

	def self.change_device_destination_host(device_receive_port, device_destination_host)
		pr_send_message(
			SERIALOSCD_HOST,
			device_receive_port,
			OSC::Message.new("/sys/host", device_destination_host)
		)
	end

	def self.change_device_message_prefix(device_receive_port, device_message_prefix)
		pr_send_message(
			SERIALOSCD_HOST,
			device_receive_port,
			OSC::Message.new("/sys/prefix", device_message_prefix.to_s)
		)
	end

	def self.change_device_rotation(device_receive_port, device_rotation)
		rotation = device_rotation.to_i
		raise ("Bad rotation: %i" % [rotation]) unless [0, 90, 180, 270].include?(rotation)

		pr_send_message(
			SERIALOSCD_HOST,
			device_receive_port,
			OSC::Message.new("/sys/rotation", rotation)
		)
	end

	def self.pr_send_request_next_device_change_msg
		pr_send_message(
			SERIALOSCD_HOST,
			SERIALOSCD_PORT,
			OSC::Message.new("/serialosc/notify", OSCSERVER_HOST, OSCSERVER_PORT)
		)
	end

	def self.pr_send_message(host, port, message)
		client = OSC::Client.new(host, port)
		client.send(message)
		pr_trace_output( "sent: '%s %s' to %s:%i" % [message.address, message.to_a.join(" "), SERIALOSCD_HOST, SERIALOSCD_PORT] )
	end

	def self.pr_trace_output(str)
		puts "SerialOSC trace: " + str if @@trace
	end
end

class SerialOSCClientNotification 
	def self.device_attached(device)
		changed(:attached, device)
		verbose_post("%s was attached" % [device])
	end

	def self.device_detached(device)
		changed(:detached, device)
		verbose_post("%s was detached" % [device])
	end

	def self.device_connected(device)
		changed(:connected, device)
		device.changed(:connected)
		verbose_post("%s was connected" % [device])
	end

	def self.device_disconnected(device)
		changed(:disconnected, device)
		device.changed(:disconnected)
		verbose_post("%s was disconnected" % [device])
	end

	def self.device_routed(device, client)
		changed(:routed, device, client)
		device.changed(:routed, client)
		verbose_post("%s was routed to client %s" % [device, client])
	end

	def self.device_unrouted(device, client)
		changed(:unrouted, device, client)
		device.changed(:unrouted, client)
		verbose_post("%s was unrouted from client %s" % [device, client])
	end

	def self.post_device_attached(device)
		puts "A SerialOSC Device was attached to the computer:"
		puts "\t#{device}"
	end

	def self.post_device_detached(device)
		puts "A SerialOSC Device was detached from the computer:"
		puts "\t#{device}"
	end

	def self.verbose_post(message)
		puts message if SerialOSCClient.verbose
	end
end

class SerialOSCClient
	attr_reader :name
	attr_reader :autoroute
	attr_accessor :permanent
	attr_reader :enc_spec, :grid_spec
	attr_reader :enc, :grid

	attr_accessor :will_free, :on_free
	@will_free = nil
	@on_free = nil

	attr_accessor :on_grid_routed, :on_grid_unrouted, :grid_refresh_action
	attr_accessor :on_enc_routed, :on_enc_unrouted, :enc_refresh_action
	attr_accessor :grid_key_action, :enc_delta_action, :enc_key_action, :tilt_action

	@on_grid_routed = nil
	@on_grid_unrouted = nil
	@grid_refresh_action = nil
	@on_enc_routed = nil
	@on_enc_unrouted = nil
	@enc_refresh_action = nil
	@grid_key_action = nil
	@enc_delta_action = nil
	@enc_key_action = nil
	@tilt_action = nil

	@@initialized = false
	@@verbose = false
	@@prefix = :'/monome'
	@@default_legacy_mode_listen_port = 8080
	@@all = []
	def self.all
		@@all
	end
	@@devices = []
	def self.devices
		@@devices
	end

	@@connected_devices = []
	@@devices_semaphore = Mutex.new

	@@recv_serialoscfunc = nil

	@@osc_recv_func = lambda do |msg, time|
		prefix, rest = *pr_split_osc_address(msg)
		device = pr_lookup_device_by_id(prefix)
		if @@connected_devices.include?(device)
			if [:'/grid/key', :'/tilt', :'/enc/delta', :'/enc/key'].include?(rest)
				osc_args = msg.to_a
				@@recv_serialoscfunc.call(rest, osc_args, time, device) if @@recv_serialoscfunc
			end
		end
	end

	@@legacy_mode_osc_recv_func = lambda do |msg, time|
		prefix, rest = *pr_split_osc_address(msg)
		device = pr_lookup_device_by_id(prefix)
		if @@connected_devices.include?(device)
			if :'/monome/press' == osc_address # note: no pattern matching is performed on OSC address
				osc_args = msg.to_a
				@@recv_serialoscfunc.call(:'/grid/key', osc_args, time, device) if @@recv_serialoscfunc
			end
		end
	end

	@@device_added_handler = lambda do |id|
		Thread.new do
			@@devices_semaphore.synchronize do
				if not pr_lookup_device_by_id(id)
					pr_update_devices_list_async(
						lambda do |devices_added_to_devices_list, devices_removed_from_devices_list|
							device = pr_lookup_device_by_id(id)
							if device
								pr_sync_after_device_list_changes([device], [])
								SerialOSCClientNotification.post_device_attached(device)
							end
						end
					)
				end
			end
		end
	end

	@@device_removed_handler = lambda do |id|
		Thread.new do
			@@devices_semaphore.synchronize do
				device = pr_lookup_device_by_id(id)
				if device
					pr_sync_after_device_list_changes([], [device])
					SerialOSCClientNotification.post_device_detached(device)
				end
			end
		end
	end

	def self.pr_split_osc_address(message)
		address = message.address
		prefix = address.split("/")[1]
		rest = address[(prefix.size+1)..-1].to_sym
		[prefix, rest]
	end

	def self.verbose
		@@verbose
	end

	def self.connected_devices
		@@connected_devices
	end

	def self.init(completion_func=nil, autoconnect=true, autodiscover=true, verbose=false)
		SerialOSC.init_osc_server # introduce completion_func lambda {
		pr_init(autoconnect, verbose)
		if autodiscover
			SerialOSC.start_tracking_connected_devices_changes(@@device_added_handler, @@device_removed_handler)
		end

		SerialOSC.registered_osc_recv_func = @@osc_recv_func

		@@initialized = true
		@@running_legacy_mode = false
		# @@devices_semaphore.synchronize do # TODO: below is async, this has no effect?
			pr_update_devices_list_async(
				lambda do |devices_added_to_devices_list, devices_removed_from_devices_list|
					post_devices
					pr_sync_after_device_list_changes(devices_added_to_devices_list, devices_removed_from_devices_list)
					completion_func.call if completion_func
				end
			)
		# end # TODO: above is async, this has no effect?
	end

	def self.legacy40h(autoconnect=true, verbose=false)
		self.pr_legacy_mode(autoconnect, verbose, LegacySerialOSCGrid("monome 40h", nil, @@default_legacy_mode_listen_port, 0))
	end

	def self.legacy64(autoconnect=true, verbose=false)
		self.pr_legacy_mode(autoconnect, verbose, LegacySerialOSCGrid("monome 64", nil, @@default_legacy_mode_listen_port, 0))
	end

	def self.legacy128(autoconnect=true, verbose=false)
		self.pr_legacy_mode(autoconnect, verbose, LegacySerialOSCGrid("monome 128", nil, @@default_legacy_mode_listen_port, 0))
	end

	def self.legacy256(autoconnect=true, verbose=false)
		self.pr_legacy_mode(autoconnect, verbose, LegacySerialOSCGrid("monome 256", nil, @@default_legacy_mode_listen_port, 0))
	end

	# TODO: test legacy mode on macbook to verify it is working
	def self.pr_legacy_mode(autoconnect=true, verbose=false, legacy_grid)
		pr_init(autoconnect, verbose)

		SerialOSC.registered_osc_recv_func = @@legacy_mode_osc_recv_func

		@@initialized = true
		@@running_legacy_mode = true

		devices_removed_from_devices_list = @@devices
		@@devices = [legacy_grid]

		post_devices
		pr_sync_after_device_list_changes(devices, devices_removed_from_devices_list)

		puts("SerialOSCClient is running in legacy mode. For an attached grid to work MonomeSerial has to run and be configured with Host Port %d, Address Prefix /monome and Listen Port %d." % [SerialOSC::OSCSERVER_PORT, legacy_grid.port])
	end

	def self.pr_init(autoconnect, verbose)
		@@autoconnect = autoconnect
		@@verbose = verbose
		pr_remove_registered_oscrecv_funcs_if_any

		if SerialOSC.is_tracking_connected_devices_changes
			SerialOSC.stop_tracking_connected_devices_changes
		end
	end

	def self.pr_sync_after_device_list_changes(devices_added_to_devices_list, devices_removed_from_devices_list)
		devices_removed_from_devices_list.each { |device| device.remove }
		devices_added_to_devices_list.each do |device|
			SerialOSCClientNotification.device_attached(device)
		end
		if @@autoconnect
			devices_added_to_devices_list.each { |device| device.connect }
		end

		pr_update_default_devices(devices_added_to_devices_list, devices_removed_from_devices_list)
	end

	def self.pr_remove_registered_oscrecv_funcs_if_any
		SerialOSC.registered_osc_recv_func = nil
	end

	def self.add_recv_serialoscfunc(func)
		@@recv_serialoscfunc = @@recv_serialoscfunc.add_func(func)
	end

	def self.remove_recv_serialoscfunc(func)
		@@recv_serialoscfunc = @@recv_serialoscfunc.remove_func(func)
	end

	def self.free_all
		@@all.dup.each { |client| client.free }
	end

	# TODO: not used in ruby version
=begin
	def self.pr_get_prefixed_address(address)
		@@prefix.to_s + address.to_s
	end
=end

	def self.pr_update_default_devices(devices_added_to_devices_list, devices_removed_from_devices_list)
		pr_update_default_grid(devices_added_to_devices_list, devices_removed_from_devices_list)
		pr_update_default_enc(devices_added_to_devices_list, devices_removed_from_devices_list)
	end

	def self.pr_update_default_grid(devices_added_to_devices_list, devices_removed_from_devices_list)
		added_and_connected = devices_added_to_devices_list.reject do |device|
			pr_device_is_enc_by_type(device)
		end.select do |device|
			device.is_connected?
		end

		connected_not_routed_to_a_client = SerialOSCGrid.connected.reject { |device| device.client != nil }

		# TODO: assure all below variants work
		case
		when (SerialOSCGrid.default == nil and not added_and_connected.empty?) then
			SerialOSCGrid.default = added_and_connected.first
		when (not @@devices.include?(SerialOSCGrid.default)) then
			SerialOSCGrid.default = case
				when (not added_and_connected.empty?) then added_and_connected_grid.first
				when (not connected_not_routed_to_a_client.empty?) then connected_not_routed_to_a_client.first
				end
		end
	end

	def self.pr_update_default_enc(devices_added_to_devices_list, devices_removed_from_devices_list)
		added_and_connected = devices_added_to_devices_list.select do |device|
			pr_device_is_enc_by_type(device)
		end.select do |device|
			device.is_connected?
		end

		connected_not_routed_to_a_client = SerialOSCEnc.connected.reject { |device| device.client != nil }

		# TODO: assure all below variants work
		case
		when (SerialOSCEnc.default == nil and not added_and_connected.empty?) then
			SerialOSCEnc.default = added_and_connected.first
		when (not @@devices.include?(SerialOSCEnc.default)) then
			SerialOSCEnc.default = case
				when (not added_and_connected.empty?) then added_and_connected_enc.first
				when (not connected_not_routed_to_a_client.empty?) then connected_not_routed_to_a_client.first
				end
		end
	end

	def self.connect_all
		@@devices.each { |device| connect(device) }
	end

	def self.connect(device)
		pr_ensure_initialized

		if not @@connected_devices.include?(device)
			if not @@running_legacy_mode
				SerialOSC.change_device_message_prefix(
					device.port,
					"/#{device.id}"
				)
				SerialOSC.change_device_destination_port(
					device.port,
					SerialOSC::OSCSERVER_PORT 
				)
			end

			@@connected_devices << device

			SerialOSCClientNotification.device_connected(device)

			pr_autoroute_device_to_clients
		end
	end

	def self.pr_autoroute_device_to_clients
		clients = SerialOSCClient.all.select { |client| client.autoroute }

		clients.each { |client| client.find_and_route_unused_devices_to_client(true) }
		clients.each { |client| client.find_and_route_unused_devices_to_client(false) }
	end

	# TODO: test spoof actions
	def self.do_grid_key_action(x, y, state, device)
		pr_dispatch_event(:'/grid/key', [x.to_i, y.to_i, state.to_i], device)
	end

	def self.do_enc_delta_action(n, delta, device)
		pr_dispatch_event(:'/enc/delta', [n.to_i, delta.to_i], device)
	end

	def self.do_tilt_action(n, x, y, z, device)
		pr_dispatch_event(:'/tilt', [n.to_i, x.to_i, y.to_i, z.to_i], device)
	end

	def self.do_enc_key_action(n, state, device)
		pr_dispatch_event(:'/enc/delta', [n.to_i, state.to_i], device)
	end

	def self.pr_dispatch_event(type, args, device)
		pr_ensure_initialized
		@@recv_serialoscfunc.call(type, args, Time.now, device) if @@recv_serialoscfunc
	end

	def self.disconnect_all
		@@devices.each { |device| disconnect(device) }
	end

	def self.disconnect(device)
		pr_ensure_initialized

		if @@connected_devices.include?(device)
			device.unroute

			@@connected_devices.delete(device)

			SerialOSCClientNotification.device_disconnected(device)
		end
	end

	def self.post_devices
		if not @@devices.empty?
			puts "SerialOSC Devices:"
			@@devices.each do |device|
				puts "\t#{device.to_s}"
			end
		else
			puts "No SerialOSC Devices are attached"
		end
	end

	def self.pr_device_is_enc_by_type(device)
		pr_is_enc_type(device.type)
	end

	def self.pr_list_entry_is_enc_by_type(device)
		pr_is_enc_type(device[:type])
	end

	def self.pr_is_enc_type(type)
		type.to_s =~ /arc/ # TODO: ruby diff
	end

	def self.pr_update_devices_list_async(completion_func=nil)
		SerialOSC.request_list_of_devices_async do |list|
			current_devices = @@devices.to_set
			found_devices = list.collect do |entry|
				existing_device = @@devices.detect { |device| device.id == entry[:id] }
				if existing_device
					existing_device
				else
					if pr_list_entry_is_enc_by_type(entry)
						SerialOSCEnc.new(entry[:type], entry[:id], entry[:receive_port])
					else
						SerialOSCGrid.new(entry[:type], entry[:id], entry[:receive_port], 0) # TODO: rotation 0 not entirely correct, should retrieve rotation from SerialOSC
					end
				end
			end.to_set

			devices_to_remove = current_devices - found_devices
			devices_to_add = found_devices - current_devices

			devices_to_remove.each { |device| @@devices.delete(device) } # TODO: diff between ruby and SC
			devices_to_add.each { |device| @@devices << device } # TODO: diff between ruby and SC

			completion_func.call(devices_to_add.to_a, devices_to_remove.to_a) if completion_func
		end
	end

	def self.pr_lookup_device_by_id(id)
		@@devices.detect { |device| device.id == id }
	end

	# TODO: not used in ruby version
=begin
	def self.pr_lookup_device_by_port(receive_port)
		@@devices.detect { |device| device.port == receive_port }
	end
=end

	def self.pr_ensure_initialized
		raise "SerialOSCClient has not been initialized" unless @@initialized
	end

	def self.grid(name, func, grid_spec=:any, autoroute=true)
		new(name, grid_spec, :none, func, autoroute)
	end

	def self.enc(name, func, enc_spec=:any, autoroute=true)
		new(name, :none, enc_spec, func, autoroute)
	end

	def self.grid_enc(name, func, grid_spec=:any, enc_spec=:any, autoroute=true)
		new(name, grid_spec, enc_spec, func, autoroute)
	end

	def initialize(name, grid_spec=:any, enc_spec=:any, func=nil, autoroute=true)
		@name = name
		@grid_spec = grid_spec
		@enc_spec = enc_spec
		@autoroute = autoroute

		do_when_initialized = lambda do
			if autoroute
				find_and_route_unused_devices_to_client(false)
			end
		end

		func.call(self) if func

		if @@initialized
			do_when_initialized.call
		else
			SerialOSCClient.init(do_when_initialized)
		end

		@@all << self
	end

	def to_s
		"SerialOSCClient (#{[@name, @grid_spec, @enc_spec]})"
	end

	def uses_grid
		@grid_spec != :none
	end

	def uses_enc
		@enc_spec != :none
	end

	def self.pr_find_grid(grid_spec, strict)
		strict_match = (pr_default_grid_if_free_and_matching(grid_spec) or pr_first_free_grid_matching(grid_spec))

		if strict
			strict_match
		else
			(strict_match or (pr_default_grid_if_free or SerialOSCGrid.unrouted.first))
		end
	end

	def self.pr_default_grid_if_free_and_matching(grid_spec)
		free_default_grid = pr_default_grid_if_free
		if free_default_grid
			if grid_matches_spec(free_default_grid, grid_spec)
				free_default_grid
			end
		end
	end

	def self.pr_default_grid_if_free
		default_grid = SerialOSCGrid.default
		if default_grid
			if not default_grid.client
				default_grid
			end
		end
	end

	def self.pr_first_free_grid_matching(grid_spec)
		SerialOSCGrid.unrouted.select { |grid| grid_matches_spec(grid, grid_spec) }.first
	end

	def self.pr_find_enc(enc_spec, strict)
		strict_match = (pr_default_enc_if_free_and_matching(enc_spec) or pr_first_free_enc_matching(enc_spec))

		if strict
			strict_match
		else
			(strict_match or (pr_default_enc_if_free or SerialOSCEnc.unrouted.first))
		end
	end

	def self.pr_default_enc_if_free_and_matching(enc_spec)
		free_default_enc = pr_default_enc_if_free
		if free_default_enc
			if enc_matches_spec(free_default_enc, enc_spec)
				free_default_enc
			end
		end
	end

	def self.pr_default_enc_if_free
		default_enc = SerialOSCEnc.default
		if default_enc
			if not default_enc.client
				default_enc
			end
		end
	end

	def self.pr_first_free_enc_matching(enc_spec)
		SerialOSCEnc.unrouted.select { |enc| enc_matches_spec(enc, enc_spec) }.first
	end

	def find_and_route_unused_devices_to_client(strict)
		find_and_route_any_unused_grid_to_client(strict)
		find_and_route_any_unused_enc_to_client(strict)
	end

	def find_and_route_any_unused_grid_to_client(strict)
		if uses_grid and (@grid == nil)
			found_grid = SerialOSCClient.pr_find_grid(@grid_spec, strict)
			if found_grid 
				pr_route_grid_to_client(found_grid)
			end
		end
	end

	def find_and_route_any_unused_enc_to_client(strict)
		if uses_enc and (@enc == nil)
			found_enc = SerialOSCClient.pr_find_enc(@enc_spec, strict)
			if found_enc
				pr_route_enc_to_client(found_enc)
			end
		end
	end

	def pr_route_grid_to_client(grid)
		@grid = grid
		@grid_key_responder = GridKeyFunc.new(
			lambda do |x, y, state, time, device|
				@grid_key_action.call(self, x, y, state) if @grid_key_action
			end,
			nil,
			nil,
			nil,
			{:client => self}
		)
		@grid_key_responder.permanent = true
		@tilt_responder = TiltFunc.new(
			lambda do |n, x, y, z, time, device|
				@tilt_action.call(self, n, x, y, z, state) if @tilt_action
			end,
			nil,
			nil,
			nil,
			nil,
			{:client => self}
		)
		@tilt_responder.permanent = true
		@grid.client = self
		@on_grid_routed.call(self) if @on_grid_routed
		SerialOSCClientNotification.device_routed(@grid, self)
		warn_if_grid_does_not_match_spec
		refresh_grid
	end

	def pr_route_enc_to_client(enc)
		@enc = enc
		@enc_delta_responder = EncDeltaFunc.new(
			lambda do |n, delta, time, device|
				@enc_delta_action.call(self, n, delta) if @enc_delta_action
			end,
			nil,
			nil,
			{:client => self}
		)
		@enc_delta_responder.permanent = true
		@enc_key_responder = EncKeyFunc.new(
			lambda do |n, state, time, device|
				@enc_key_action.call(self, n, state) if @enc_key_action
			end,
			nil,
			nil,
			{:client => self}
		)
		@enc_key_responder.permanent = true
		@enc.client = self
		@on_enc_routed.call(self) if @on_enc_routed
		SerialOSCClientNotification.device_routed(@enc, self)
		warn_if_enc_does_not_match_spec
		refresh_enc
	end

	def to_serialoscclient
		self
	end

	def grab_devices
		grab_grid
		grab_enc
	end

	def grab_grid
		if uses_grid and not SerialOSCGrid.all.empty?
			SerialOSCClient.route(SerialOSCGrid.all.first, self)
		end
	end

	def grab_enc
		if uses_enc and not SerialOSCEnc.all.empty?
			SerialOSCClient.route(SerialOSCEnc.all.first, self)
		end
	end

	def self.route(device, client)
		pr_route(device, client.to_serialoscclient)
	end

	def self.pr_route(device, client)
		if device.respond_to? :led_set
			pr_route_grid(device, client)
		end
		if device.respond_to? :ring_set
			pr_route_enc(device, client)
		end
	end

	def self.pr_route_grid(grid, client)
		if client.uses_grid
			client.unroute_grid if client.grid
			grid.unroute if grid.client
			client.pr_route_grid_to_client(grid)
		else
			raise("Client %s does not use a grid" % [client])
		end
	end

	def self.pr_route_enc(enc, client)
		if client.uses_enc
			client.unroute_enc if client.enc
			enc.unroute if enc.client
			client.pr_route_enc_to_client(enc)
		else
			raise("Client %s does not use an enc" % [client])
		end
	end

	def self.post_routings
		@@all.each do |client|
			puts client
			if client.uses_grid
				puts(
					if client.grid
						"\trouted to %s" % [client.grid]
					else
						"\tno grid routed"
					end
				)
			end
			if client.uses_enc
				puts(
					if client.enc
						"\trouted to %s" % [client.enc]
					else
						"\tno enc routed"
					end
				)
			end
		end
	end

	def warn_if_grid_does_not_match_spec
		"Note: Grid %s does not match client %s spec: %s" % [@grid, self, @grid_spec] unless SerialOSCClient.grid_matches_spec(@grid, @grid_spec)
	end

	def warn_if_enc_does_not_match_spec
		"Note: Enc %s does not match client %s spec: %s" % [@enc, self, @enc_spec] unless SerialOSCClient.enc_matches_spec(@enc, @enc_spec)
	end

	def self.grid_matches_spec(grid, grid_spec)
		num_rows = grid.num_rows
		num_cols = grid.num_cols
		# TODO: verify this works
		case
		when grid_spec == :any then true
		when (grid_spec.respond_to?(:key) and grid_spec.respond_to?(:value)) then
			(grid_spec.key == :num_cols) and (grid_spec.value == num_cols) or (grid_spec.key == :num_rows) and (grid_spec.value == num_rows)
		when grid_spec.respond_to?(:keys)
			(grid_spec[:num_cols] == num_cols) and (grid_spec[:num_rows] == num_rows)
		end
	end

	def self.enc_matches_spec(enc, enc_spec)
		(enc_spec == :any) or (enc_spec == @enc.num_encs)
	end

	def refresh_grid
		if @grid
			clear_leds
			@grid_refresh_action.call(self) if @grid_refresh_action
		end
	end

	def refresh_enc
		if @enc
			clear_rings
			@enc_refresh_action.call(self) if @enc_refresh_action
		end
	end

	def unroute_grid
		if @grid
			grid_to_unroute = @grid
			@grid.client = nil
			@grid.clear_leds
			@grid = nil
			@grid_key_responder.free
			@tilt_responder.free
			@on_grid_unrouted.call(self, grid_to_unroute) if @on_grid_unrouted
			SerialOSCClientNotification.device_unrouted(grid_to_unroute, self)
		end
	end

	def unroute_enc
		if @enc
			enc_to_unroute = @enc
			@enc.client = nil
			@enc.clear_rings
			@enc = nil
			@enc_delta_responder.free
			@enc_key_responder.free
			@on_enc_unrouted.call(self, enc_to_unroute) if @on_enc_unrouted
			SerialOSCClientNotification.device_unrouted(enc_to_unroute, self)
		end
	end

	def free
		@will_free.call(self) if @will_free
		unroute_grid if uses_grid
		unroute_enc if uses_enc
		@on_free.call(self) if @on_free
		@@all.delete(self)
	end

	def clear_leds
		@grid.clear_leds if @grid
	end

	def activate_tilt
		@grid.activate_tilt if @grid
	end

	def deactivate_tilt
		@grid.deactivate_tilt if @grid
	end

	def led_set(x, y, state)
		@grid.led_set(x, y, state) if @grid
	end

	def led_all(state)
		@grid.led_all(state) if @grid
	end

	def led_map(x_offset, y_offset, bitmasks)
		@grid.led_map(x_offset, y_offset, bitmasks) if @grid
	end

	def led_row(x_offset, y, bitmasks)
		@grid.led_row(x_offset, y, bitmasks) if @grid
	end

	def led_col(x, y_offset, bitmasks)
		@grid.led_col(x, y_offset, bitmasks) if @grid
	end

	def led_intensity(i)
		@grid.led_intensity(i) if @grid
	end

	def led_level_set(x, y, l)
		@grid.led_level_set(x, y, l) if @grid
	end

	def led_level_all(l)
		@grid.led_level_all(l) if @grid
	end

	def led_level_map(x_offset, y_offset, levels)
		@grid.led_level_map(x_offset, y_offset, levels) if @grid
	end

	def led_level_row(x_offset, y, levels)
		@grid.led_level_row(x_offset, y, levels) if @grid
	end

	def led_level_col(x, y_offset, levels)
		@grid.led_level_col(x, y_offset, levels) if @grid
	end

	def tilt_set(n, state)
		@grid.tilt_set(n, state) if @grid
	end

	def clear_rings
		@enc.clear_rings if @enc
	end

	def ring_set(n, x, level)
		@enc.ring_set(n, x, level) if @enc
	end

	def ring_all(n, level)
		@enc.ring_all(n, level) if @enc
	end

	def ring_map(n, levels)
		@enc.ring_map(n, levels) if @enc
	end

	def ring_range(n, x1, x2, level)
		@enc.ring_range(n, x1, x2, level) if @enc
	end
end

# TODO
def test1
	if $ARC
		Thread.new do
			16.times do |a|
				16.times do |b|
					$ARC.ring_all(0, b)
					sleep 0.05
				end
				16.times do |b|
					$ARC.ring_all(0, 15-b)
					sleep 0.05
				end
			end
		end
	else
		puts "no arc in $ARC, yo"
	end
end

def spawn_test_client
	SerialOSCClient.grid("test", lambda do |client|
	end)
end

def spawn_test_client2
	SerialOSCClient.enc("test", lambda do |client|
	end)
end

