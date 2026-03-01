set PROJECT_NAME spi_master
set PROJECT_DIR ./vivado
set PART xc7a35tcpg236-1

create_project $PROJECT_NAME $PROJECT_DIR -part $PART -force

add_files [glob ../rtl/*.sv]

update_compile_order -fileset sources_1

set_property top spi_master [current_fileset]

save_project