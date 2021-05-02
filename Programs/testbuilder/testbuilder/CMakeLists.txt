# CMakeList.txt : CMake project for testbuilder, include source and define
# project specific logic here.
#
cmake_minimum_required (VERSION 3.8)

# Add source to this project's executable.
add_executable (testbuilder "testbuilder.cpp" "testbuilder.h" "alutests.h" "alutests.cpp")

target_link_libraries(testbuilder PUBLIC fmt::fmt)
# TODO: Add tests and install targets if needed.
