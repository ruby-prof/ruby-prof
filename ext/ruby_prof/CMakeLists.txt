cmake_minimum_required (VERSION 3.26)
#set(CMAKE_MESSAGE_LOG_LEVEL DEBUG)

project(ruby-prof)

add_library (${CMAKE_PROJECT_NAME} SHARED
        "rp_allocation.c"
        "rp_call_tree.c"
        "rp_call_trees.c"
        "rp_measure_allocations.c"
        "rp_measure_process_time.c"
        "rp_measure_wall_time.c"
        "rp_measurement.c"
        "rp_method.c"
        "rp_profile.c"
        "rp_stack.c"
        "rp_thread.c"
        "ruby_prof.c")

# Ruby
find_package(Ruby REQUIRED)
target_include_directories(${CMAKE_PROJECT_NAME} PUBLIC ${Ruby_INCLUDE_DIR} ${Ruby_CONFIG_INCLUDE_DIR})
target_link_libraries(${CMAKE_PROJECT_NAME} ${Ruby_LIBRARY})

set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
        PREFIX ""
        SUFFIX ".so"
        OUTPUT_NAME "ruby_prof"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/../../../../../lib/${Ruby_VERSION_MAJOR}.${Ruby_VERSION_MINOR}" # Windows
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/../../../../../lib/${Ruby_VERSION_MAJOR}.${Ruby_VERSION_MINOR}" # Not Windows
        C_STANDARD 99)

