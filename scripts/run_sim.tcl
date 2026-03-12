set PROJECT_NAME spi_master
set PROJECT_DIR ./vivado
set PART xc7a35tcpg236-1

if { [file exists ${PROJECT_DIR}/${PROJECT_NAME}.xpr] } {
    open_project ${PROJECT_DIR}/${PROJECT_NAME}.xpr
} else {
    create_project $PROJECT_NAME $PROJECT_DIR -part $PART -force
    add_files [glob ./rtl/*.sv]
}

add_files -fileset sim_1 ./sim/tb_spi_master.sv

set_property top tb_spi_master [get_filesets sim_1]

launch_simulation

run all
