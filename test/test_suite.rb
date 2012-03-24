# encoding: utf-8

# Change to current directory so relative
# requires work.
dir = File.dirname(__FILE__)
Dir.chdir(dir)

require './test_helper'

require './aggregate_test'
require './basic_test'
require './duplicate_names_test'
require './dynamic_method_test'
require './enumerable_test'
require './exceptions_test'
require './exclude_threads_test'
require './line_number_test'

require './measure_allocations_test'
require './measure_cpu_time_test'
require './measure_gc_runs_test'
require './measure_gc_time_test'
require './measure_memory_test'
require './measure_process_time_test'
require './measure_wall_time_test'

require './method_elimination_test'
require './module_test'
require './multi_printer_test'
require './no_method_class_test'
require './prime_test'
require './printers_test'
require './recursive_test'
require './singleton_test'
require './stack_test'
require './stack_printer_test'
require './start_stop_test'
require './thread_test'
require './unique_call_path_test'

# Can't use this one here cause it breaks
# the rest of the unit tets (Ruby Prof gets
# started twice).
#require './profile_unit_test'
