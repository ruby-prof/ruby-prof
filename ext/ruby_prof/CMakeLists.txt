# CMakeList.txt : Top-level CMake project file, do global configuration
# and include sub-projects here.
#
cmake_minimum_required (VERSION 3.8)

project(ruby-prof)

# Enable Hot Reload for MSVC compilers if supported.
if (POLICY CMP0141)
  cmake_policy(SET CMP0141 NEW)
  set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT "$<IF:$<AND:$<C_COMPILER_ID:MSVC>,$<CXX_COMPILER_ID:MSVC>>,$<$<CONFIG:Debug,RelWithDebInfo>:EditAndContinue>,$<$<CONFIG:Debug,RelWithDebInfo>:ProgramDatabase>>")
endif()

# Add source to this project's executable.
add_library (ruby_prof SHARED
        "rp_allocation.c"
        "rp_call_tree.c"
        "rp_call_trees.c"
        "rp_measure_allocations.c"
        "rp_measure_memory.c"
        "rp_measure_process_time.c"
        "rp_measure_wall_time.c"
        "rp_measurement.c"
        "rp_method.c"
        "rp_profile.c"
        "rp_stack.c"
        "rp_thread.c"
        "ruby_prof.c")

set_target_properties(ruby_prof PROPERTIES
        PREFIX ""
        OUTPUT_NAME "ruby_prof"
        SUFFIX ".so"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/..")

set_property(TARGET ruby_prof PROPERTY C_STANDARD 99)

if (MSVC)
  target_include_directories(ruby_prof PRIVATE "C:/msys64/usr/local/ruby-3.2.1-vc/include/ruby-3.2.0")
  target_include_directories(ruby_prof PRIVATE "C:/msys64/usr/local/ruby-3.2.1-vc/include/ruby-3.2.0/x64-mswin64_140")
  target_link_libraries(ruby_prof "C:/msys64/usr/local/ruby-3.2.1-vc/lib/x64-vcruntime140-ruby320.lib")
elseif (MINGW)
  target_compile_options(ruby_prof PRIVATE -Wa,-mbig-obj)
  target_include_directories(ruby_prof PRIVATE "C:/msys64/usr/local/ruby-3.2.0/include/ruby-3.2.0")
  target_include_directories(ruby_prof PRIVATE "C:/msys64/usr/local/ruby-3.2.0/include/ruby-3.2.0/x64-mingw-ucrt")
  target_link_libraries(ruby_prof "C:/msys64/usr/local/ruby-3.2.0/lib/libx64-ucrt-ruby320.dll.a")
else ()
  target_link_libraries(ruby_prof "/usr/lib64/libruby.so")
endif ()
