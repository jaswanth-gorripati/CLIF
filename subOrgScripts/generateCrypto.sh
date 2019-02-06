#!/bin/bash

BROWN='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
LBLUE='\033[1;34m'
NC='\033[0m'
GREEN='\033[0;32m'
BIN_PATH=$1
O_NAME=$2
d_ORG=$3

# Using docker-compose.yaml, replace constants with private key file names
# generated by the cryptogen tool and output a docker-compose-ca-base.yaml specific to this
# configuration


function SSHsendJsonFile () {
  cd $I_PATH
  echo " sending files to ${USERNAME}@${IP}:${DESTPATH}"
  scp ../channel-artifacts/${DOMAIN}.json ${USERNAME}@${IP}:${DESTPATH}
  if [ "$?" -ne 0 ]; then
    echo "Failed to send required files..."
    exit 1
  fi
  scp ../channel-artifacts/crypto-config/peerOrganizations/XyzHospitals.example.com/peers/peer0.XyzHospitals.example.com/msp/tlscacerts/tlsca.XyzHospitals.example.com-cert.pem ${USERNAME}@${IP}:${DESTPATH}
  if [ "$?" -ne 0 ]; then
    echo "Failed to send required files..."
    exit 1
  fi
}
function sendJsonFile () {
  echo -e "${GREEN} sending files to ${d_ORG}${NC}"
  cp ./${O_NAME}.json ~/CLIF/${d_ORG}/
  if [ "$?" -ne 0 ]; then
    echo "Failed to send required files..."
    exit 1
  fi
}
# Generate orderer genesis block and channel configuration transaction
function generateChannelArtifacts() {
    cd $BIN_PATH
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo -e "${RED}configtxgen tool not found. exiting${NC}"
    exit 1
  fi

  if [ -f "${O_NAME}.json" ]; then
    rm ${O_NAME}.json
  fi

  # sed on MacOSX does not support -i flag with a null extension. We will use
  # 't' for our back-up's extension and depete it at the end of the function
  ARCH=`uname -s | grep Darwin`
  if [ "$ARCH" == "Darwin" ]; then
    OPTS="-it"
  else
    OPTS="-i"
  fi

  CONFIGTX_FILE="configtx.yaml"
  H_P=$(echo ~)
  sed $OPTS "s:HOME_PATH:$H_P:g" "$CONFIGTX_FILE"
  echo -e "${GREEN}"
  echo "##########################################################"
  echo "#########  Generating  ${O_NAME}.json file ##############"
  echo "##########################################################"
  echo -e "${NC}"
  # Note: For some unknown reason (at least for now) the block file can't be
  # named orderer.genesis.block or the orderer will fail to launch!
   configtxgen -printOrg ${O_NAME}MSP > ${O_NAME}.json
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi
  echo -e "${BROWN} CRYPTO FILES GENERATED FOR ${O_NAME}${NC}"
  #sendJsonFile
}

function replacePrivateKey() {
  #cd ../
  echo $PWD
  # sed on MacOSX does not support -i flag with a null extension. We will use
  # 't' for our back-up's extension and depete it at the end of the function
  ARCH=`uname -s | grep Darwin`
  if [ "$ARCH" == "Darwin" ]; then
    OPTS="-it"
  else
    OPTS="-i"
  fi
  COMPOSE_CA_FILE=./docker-compose.yaml
  
  # The next steps will replace the template's contents with the
  # actual values of the private key file names for the two CAs.
  CURRENT_DIR=$PWD
  #echo $BIN_PATH
  cd ./crypto-config/peerOrganizations/$O_NAME.example.com/ca/
  PRIV_KEY=$(ls *_sk)
  cd "$CURRENT_DIR"/
  echo $PWD
  sed $OPTS "s/CA_PRIVATE_KEY/${PRIV_KEY}/g" "$COMPOSE_CA_FILE"
  # If MacOSX, remove the temporary backup of the docker-compose file
  if [ "$ARCH" == "Darwin" ]; then
    rm "$COMPOSE_CA_FILE"
  fi
  generateChannelArtifacts
}


# Generates Org certs using cryptogen tool
function generateCerts (){
  export PATH=${BIN_PATH}bin:$BIN_PATH:$PATH
  export FABRIC_CFG_PATH=$BIN_PATH

  cd $BIN_PATH
  #echo $PWD
  which cryptogen
  if [ "$?" -ne 0 ]; then
    echo -e  "${RED}cryptogen tool not found. exiting${NC}"
    exit 1
  fi
  echo -e "${GREEN}"
  echo "##########################################################"
  echo "##### Generate certificates using cryptogen tool #########"
  echo "##########################################################"
  echo -e "${NC}"
#   if [ -d "channel-artifacts" ]; then
#     rm -Rf channel-artifacts
#   fi
#   cd ../
#   mkdir channel-artifacts
#   cd ./channel-artifacts/
  if [ -d "crypto-config" ]; then
    rm -Rf crypto-config
  fi

  # sed on MacOSX does not support -i flag with a null extension. We will use
  # 't' for our back-up's extension and depete it at the end of the function
  ARCH=`uname -s | grep Darwin`
  if [ "$ARCH" == "Darwin" ]; then
    OPTS="-it"
  else
    OPTS="-i"
  fi

  CRYPTO_CONFIG_FILE="crypto-config.yaml"
  cryptogen generate --config=./${CRYPTO_CONFIG_FILE}
  if [ "$?" -ne 0 ]; then
    echo -e "${RED}Failed to generate certificates...${NC}"
    exit 1
  fi
  replacePrivateKey
}
generateCerts