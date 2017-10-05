require 'test/unit'
require 'serialoscclient'

class TestProcListExtensions < Test::Unit::TestCase
	def setup
		@notifications = Array.new
		@proc1 = lambda { |x| @notifications << (x + 1) }
		@proc2 = lambda { |x| @notifications << (x - 5) }
		@proc3 = lambda { |x| @notifications << (x * 5) }
	end

	test "adding a proc to nil should return a proc" do
		assert_equal(@proc1, nil.add_proc(@proc1))
	end

	test "adding two or more procs to nil should return a proclist" do
		list = nil.add_proc(@proc1, @proc2)
		assert_equal(ProcList, list.class)
		assert_equal(@proc1, list.array[0])
		assert_equal(@proc2, list.array[1])
	end

	test "adding a proc to a proc should return a proclist" do
		list = @proc1.add_proc(@proc2)
		assert_equal(ProcList, list.class)
		assert_equal(@proc1, list.array[0])
		assert_equal(@proc2, list.array[1])
	end

	test "adding a proc to a proclist should return a proclist with the proc added" do
		proclist = ProcList.new(@proc1, @proc2)

		list = proclist.add_proc(@proc3)

		assert_equal(ProcList, list.class)
		assert_equal(@proc1, list.array[0])
		assert_equal(@proc2, list.array[1])
		assert_equal(@proc3, list.array[2])
	end

	test "remove proc should return last proc when only one proc is left" do
		proclist = ProcList.new(@proc1, @proc2)

		ret = proclist.remove_proc(@proc1)

		assert_equal(@proc2, ret)
	end

	test "remove proc should return nil when the last proc was removed" do
		proclist = ProcList.new(@proc1, @proc2)

		proclist.remove_proc(@proc2)
		ret = proclist.remove_proc(@proc1)

		assert_equal(nil, ret)
	end

	test "procs should be evaluated in the order they have in the proclist array" do
		proclist = ProcList.new(@proc1, @proc2, @proc3)

		proclist.call(5)

		assert_equal([6, 0, 25], @notifications)
	end
end

class TestDependancyExtension < Test::Unit::TestCase
	test "it should be possible to observe changes of a model" do
		model = Object.new
		observer = Object.new

		def observer.update(the_changed, the_changer, arg1, arg2, arg3)
			@notifications = Array.new unless (defined? @notifications)
			@notifications << [the_changed, the_changer, arg1, arg2, arg3]
		end

		def observer.notifications
			@notifications
		end

		model.add_dependant(observer)

		model.changed(:property, :arg1, :arg2, :arg3)

		assert_equal(
			observer.notifications,
			[
				[
					model,
					:property,
					:arg1,
					:arg2,
					:arg3
				]
			]
		)
	end
end
