#!/bin/bash

function install() {
    set -e

    # Array of supported versions
    declare -a versions=('trusty' 'xenial' 'yakkety', 'bionic');

    # check the version and extract codename of ubuntu if release codename not provided by user
    if [ -z "$1" ]; then
        source /etc/lsb-release || \
            (echo "Error: Release information not found, run script passing Ubuntu version codename as a parameter"; exit 1)
        CODENAME=${DISTRIB_CODENAME}
    else
        CODENAME=${1}
    fi

    # check version is supported
    if echo ${versions[@]} | grep -q -w ${CODENAME}; then
        echo "Installing Hyperledger Composer prereqs for Ubuntu ${CODENAME}"
    else
        echo "Error: Ubuntu ${CODENAME} is not supported"
        exit 1
    fi

    # Update package lists
    echo "# Updating package lists"
    sudo apt-add-repository -y ppa:git-core/ppa
    sudo apt-get update
    echo "# Installing Git"
    sudo apt-get install -y git
    # Install Git
    which git
    if [ $? -eq 0 ];then
        echo "# Installing Git"
        sudo apt-get install -y git
        else 
        echo "git is installed"
        git_ver=$(git version)
        echo "git version: ${git_ver}"
    fi


    # Install nvm dependencies
    echo "# Installing nvm dependencies"
    sudo apt-get -y install build-essential libssl-dev

    sudo apt install curl
    # Execute nvm installation script
    echo "# Executing nvm installation script"
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash

    # Set up nvm environment without restarting the shell
    export NVM_DIR="${HOME}/.nvm"
    [ -s "${NVM_DIR}/nvm.sh" ] && . "${NVM_DIR}/nvm.sh"
    [ -s "${NVM_DIR}/bash_completion" ] && . "${NVM_DIR}/bash_completion"

    # Install node
    echo "# Installing nodeJS"
    nvm install 10
    nvm use 10

    # Ensure that CA certificates are installed
    sudo apt-get -y install apt-transport-https ca-certificates

    # Add Docker repository key to APT keychain
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    # Update where APT will search for Docker Packages
    echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu ${CODENAME} stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list

    # Update package lists
    sudo apt-get update

    # Verifies APT is pulling from the correct Repository
    sudo apt-cache policy docker-ce

    # Install kernel packages which allows us to use aufs storage driver if V14 (trusty/utopic)
    if [ "${CODENAME}" == "trusty" ]; then
        echo "# Installing required kernel packages"
        sudo apt-get -y install linux-image-extra-$(uname -r) linux-image-extra-virtual
    fi

    # Install Docker
    echo "# Installing Docker"
    sudo apt-get -y install docker-ce

    # Add user account to the docker group
    sudo usermod -aG docker $(whoami)
    sleep 2
    newgrp docker

    # Install docker compose
    echo "# Installing Docker-Compose"
    sudo curl -L "https://github.com/docker/compose/releases/download/1.13.0/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # Install python v2 if required
    set +e
    COUNT="$(python -V 2>&1 | grep -c 2.)"
    if [ ${COUNT} -ne 1 ]
    then
    sudo apt-get install -y python-minimal
    fi

    # Install unzip, required to install hyperledger fabric.
    sudo apt-get -y install unzip

    # Print installation details for user
    echo ''
    echo 'Installation completed, versions installed are:'
    echo ''
    echo -n 'Node:           '
    node --version
    echo -n 'npm:            '
    npm --version
    echo -n 'Docker:         '
    docker --version
    echo -n 'Docker Compose: '
    docker-compose --version
    echo -n 'Python:         '
    python -V

    # Print reminder of need to logout in order for these changes to take effect!
    echo ''
    echo "signing out from system and please login agian and check the versions and then please donot select any preinstallation commands again"

    echo "setting environment variables"

}


function pullingimages(){

    declare -a dockerimage=(orderer peer ccenv tools)

    docker pull hyperledger/fabric-ca:1.4.6
    for cn in "${dockerimage[@]}"
    do
        echo "pulling hyperledger/fabric-${cn} image with verison 2.1.0"
        docker pull hyperledger/fabric-${cn}:2.1.0
    done
    
    declare -a dockerimage1=(kafka zookeeper couchdb baseimage baseos)

    for cn in "${dockerimage1[@]}"
    do 
        echo "pulling hyperledger/fabric-${cn} image with verison 0.4.18"
        docker pull hyperledger/fabric-${cn}:0.4.18
    done
        
}

install
pullingimages


