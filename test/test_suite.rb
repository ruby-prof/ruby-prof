# encoding: utf-8

require File.expand_path("../test_helper", __FILE__)

%w(aggregate_test
   basic_test
   call_info_visitor_test
   duplicate_names_test
   dynamic_method_test
   enumerable_test
   exceptions_test
   exclude_threads_test
   line_number_test

   measure_allocations_test
   measure_cpu_time_test
   measure_gc_runs_test
   measure_gc_time_test
   measure_memory_test
   measure_process_time_test
   measure_wall_time_test

   method_elimination_test
   module_test
   multi_printer_test
   no_method_class_test
   pause_test
   prime_test
   printers_test
   recursive_test
   singleton_test
   stack_test
   stack_printer_test
   start_stop_test
   thread_test
   tricky_test
   unique_call_path_test).each do |test|
  require File.expand_path("../#{test}", __FILE__)
end