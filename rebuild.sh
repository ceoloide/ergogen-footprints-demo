#!/bin/sh
container_cmd=docker
# Ensure we switch to the /board working directory, pointing it
# at the repo root (when running the script from there)
container_args="-w /board -v $(pwd):/board --rm"

# Define the boards to autoroute and export, and the plates
boards="ergogen_footprints_demo"
# kicad_auto_image="ghcr.io/inti-cmnb/kicad7_auto:latest"
kicad_auto_image="setsoft/kicad_auto:ki8"
# freerouting_cli_image="ceoloide/kicad_auto:nightly"
freerouting_cli_image="ceoloide/ergogen:snapshot"
# freerouting_cli_image="soundmonster/freerouting_cli:v0.1.0"

# Cleanup Freerouting log outpus
if [ -e freerouting/freerouting.log ]; then
    rm freerouting/freerouting.log
fi
if [ -e logs/freerouting.log ]; then
    rm logs/freerouting.log
fi

if [ ! -e freerouting/freerouting-2.0.0.jar ]; then
    curl https://github.com/freerouting/freerouting/releases/download/v2.0.0/freerouting-2.0.0.jar -L -o freerouting/freerouting-2.0.0.jar
fi

if [ ! -e freerouting/freerouting-SNAPSHOT.jar ]; then
    curl https://github.com/freerouting/freerouting/releases/download/SNAPSHOT/freerouting-SNAPSHOT-20241111_140100.jar -L -o freerouting/freerouting-SNAPSHOT.jar
fi

for board in ${boards}
do
    echo "\n\n>>>>>> Processing $board <<<<<<\n\n"

    # Cleanup the outputs
    rm -f ergogen/output/pcbs/${board}.dsn  
    rm -f ergogen/output/pcbs/${board}.ses  
    rm -f ergogen/output/pcbs/${board}.pro  
    rm -f ergogen/output/pcbs/${board}_autorouted.kicad_pcb  
 
    if [ -e ergogen/output/pcbs/${board}.kicad_pcb ]; then
        echo Export DSN 
        ${container_cmd} run ${container_args} ${kicad_auto_image} kibot/export_dsn.py -b ergogen/output/pcbs/${board}.kicad_pcb -o ergogen/output/pcbs/${board}.dsn
        ${container_cmd} run ${container_args} ${kicad_auto_image} kibot -b ergogen/output/pcbs/${board}.kicad_pcb -c kibot/default.kibot.yaml
    fi
    if [ -e ergogen/output/pcbs/${board}.dsn ]; then
        echo Autoroute PCB
        # ${container_cmd} run ${container_args} ${freerouting_cli_image} java -Dlog4j.configurationFile=file:./freerouting/log4j2.xml -jar /opt/freerouting_cli.jar -de ergogen/output/pcbs/${board}.dsn -do ergogen/output/pcbs/${board}.ses -dr freerouting/freerouting.rules -mp 20
        ${container_cmd} run ${container_args} ${freerouting_cli_image} java -Dlog4j.configurationFile=file:./freerouting/log4j2.xml -jar /opt/freerouting.jar -de ergogen/output/pcbs/${board}.dsn -do ergogen/output/pcbs/${board}.ses --user-data-path ./freerouting -mp 20 -mt 1 -dct 0 --gui.enabled=false --profile.email=marco.massarelli@gmail.com
        # java -Dlog4j.configurationFile=file:./freerouting/log4j2.xml -jar freerouting/freerouting-2.0.0.jar -de ergogen/output/pcbs/${board}.dsn -do ergogen/output/pcbs/${board}.ses --user-data-path ./freerouting -mp 20 -mt 1 -dct 0 --gui.enabled=false --profile.email=marco.massarelli@gmail.com
        # java -Dlog4j.configurationFile=file:./freerouting/log4j2.xml -jar freerouting/freerouting-SNAPSHOT.jar -de ergogen/output/pcbs/${board}.dsn -do ergogen/output/pcbs/${board}.ses --user-data-path ./freerouting -mp 20 -mt 1 -dct 0 --gui.enabled=false --profile.email=marco.massarelli@gmail.com
    fi
    if [ -e ergogen/output/pcbs/${board}.ses ]; then
        echo "Import SES"
        ${container_cmd} run ${container_args} ${kicad_auto_image} kibot/import_ses.py -b ergogen/output/pcbs/${board}.kicad_pcb -s ergogen/output/pcbs/${board}.ses -o ergogen/output/pcbs/${board}_autorouted.kicad_pcb
    fi
    if [ -e ergogen/output/pcbs/${board}_autorouted.kicad_pcb ]; then
        ${container_cmd} run ${container_args} ${kicad_auto_image} kibot -b ergogen/output/pcbs/${board}_autorouted.kicad_pcb -c kibot/boards.kibot.yaml
    fi
done

# Docker runs as root and causes issues with file ownership
sudo chown $USER -R ergogen
sudo chown $USER -R freerouting
