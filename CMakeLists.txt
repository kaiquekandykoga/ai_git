cmake_minimum_required(VERSION 3.10)
project(ai_git VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(GNUInstallDirs)

find_package(CURL REQUIRED)

add_executable(ai_git
    src/main.cpp
    src/git.cpp
    src/ollama.cpp
)

target_include_directories(ai_git PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(ai_git PRIVATE CURL::libcurl)

install(TARGETS ai_git DESTINATION ${CMAKE_INSTALL_BINDIR})