set(CMAKE_C_FLAGS_DEBUG "-DUSE_ASSERT_CHECKING=1")

if (UNIX)
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -L${PG_LIBDIR}")
  set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -L${PG_LIBDIR}")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${PG_CFLAGS}")
  set(CMAKE_CPP_FLAGS "${CMAKE_CPP_FLAGS} ${PG_CPPFLAGS}")
  set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -g")
endif (UNIX)

if (APPLE)
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -multiply_defined suppress")
  set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -multiply_defined suppress -Wl,-undefined,dynamic_lookup -Wl,-dead_strip_dylibs -bundle_loader ${PG_BINDIR}/postgres")
elseif (WIN32)
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /MANIFEST:NO")
  set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} /MANIFEST:NO")
endif (APPLE)

include_directories (${CMAKE_CURRENT_BINARY_DIR} ${PG_INCLUDEDIR} ${PG_INCLUDEDIR_SERVER})

if (WIN32)
  set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} ${PG_LIBDIR}/postgres.lib ws2_32.lib")
  set(CMAKE_C_FLAGS "-D_CRT_SECURE_NO_WARNINGS")
  include_directories(${PG_INCLUDEDIR_SERVER}/port/win32)

if (MSVC)
  include_directories(${PG_INCLUDEDIR_SERVER}/port/win32_msvc)
endif (MSVC)
endif (WIN32)

set(HEADERS
  timestamp9.h)

set(SOURCES
  timestamp9.cc)

add_library(${PROJECT_NAME} MODULE ${SOURCES} ${HEADERS})

set_target_properties(${PROJECT_NAME} PROPERTIES
    OUTPUT_NAME ${PROJECT_NAME}
    PREFIX "")

# Function to concatenate all files in SRC_FILE_LIST into file OUTPUT_FILE
function(cat_files SRC_FILE_LIST OUTPUT_FILE)
  if (WIN32)
    # Make list of files into string of files separated by "+"
    # to make Windows copy concatenate them

    file(TO_NATIVE_PATH "${SRC_FILE_LIST}" SRC_FILE_LIST_NATIVE)
    string(REPLACE ";" ";+" SQL_LIST_JOINED "${SRC_FILE_LIST_NATIVE}")

    file(TO_NATIVE_PATH "${OUTPUT_FILE}" OUTPUT_FILE_NATIVE)

    set(CAT_CMD copy /B /y ${SQL_LIST_JOINED} "\"${OUTPUT_FILE_NATIVE}\"" >NUL)
  else ()
    set(CAT_CMD cat ${SRC_FILE_LIST} > ${OUTPUT_FILE})
  endif ()
  add_custom_command(
    OUTPUT ${OUTPUT_FILE}
    DEPENDS ${SRC_FILE_LIST}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMAND ${CAT_CMD}
    COMMENT "Generating ${OUTPUT_FILE}"
  )
endfunction()


set(INSTALL_FILE ${PROJECT_NAME}--${PROJECT_VERSION_MOD}.sql)
cat_files("timestamp9.sql" ${CMAKE_CURRENT_BINARY_DIR}/${INSTALL_FILE})
add_custom_target(sqlfile ALL DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${INSTALL_FILE})

set(MOD_FILES
        timestamp9--0.1.0--0.2.0.sql
        )

add_custom_target(sqlupdatescripts ALL DEPENDS ${MOD_FILES})

install(
  TARGETS ${PROJECT_NAME}
  DESTINATION ${PG_PKGLIBDIR})

install(
  FILES ${CMAKE_CURRENT_BINARY_DIR}/${INSTALL_FILE}
        ${MOD_FILES}
  DESTINATION "${PG_SHAREDIR}/extension")
