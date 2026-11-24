idf_component_register(SRCS "cmd_router.c"
                    INCLUDE_DIRS .
                    REQUIRES console nvs_flash driver spi_flash esp_wifi)

target_include_directories(${COMPONENT_TARGET} INTERFACE ${CMAKE_CURRENT_LIST_DIR})
