
project(GRAPHICS_PIPELINE)

include_directories( ${CMAKE_CURRENT_SOURCE_DIR}/../vendor/include)
file(GLOB SOURCES
     "*.h"
     "*.cpp"
)

add_library(GRAPHICS_PIPELINE ${SOURCES})