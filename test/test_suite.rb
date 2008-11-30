require 'test/unit'

require 'aggregate_test'
require 'basic_test'
require 'duplicate_names_test'
require 'exceptions_test'
require 'line_number_test'
require 'measurement_test'
require 'module_test'
require 'no_method_class_test'
require 'prime_test'
require 'printers_test'
require 'recursive_test'
require 'singleton_test'
require 'stack_test'
require 'start_stop_test'
require 'thread_test'
require 'unique_call_path_test'

# Can't use this one here cause it breaks
# the rest of the unit tets (Ruby Prof gets
# started twice).
#require 'profile_unit_test'
