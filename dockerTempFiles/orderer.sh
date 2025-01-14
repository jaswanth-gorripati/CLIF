#!/bin/bash
DTSPATH="./services.yaml"
function addOrderer() {
    ORDR_ID=$1
    AddNumber=$2
    port1=$(expr 7050 + $2)
    EXTERNAL_NETWORK=$3
    OR_P_NAME=$4
    KF_STR=$5
    KFS_Count=$6
    if [ "${KF_STR}" != " " ]; then
      d_type="$7"
      else
      d_type="$6"
    fi
if [ "$d_type" != "Docker-compose" ]; then
cat << EOF >> ${DTSPATH}
  orderer${ORDR_ID}:
    image: hyperledger/fabric-orderer:2.1.0
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
    hostname: orderer${ORDR_ID}.example.com
EOF
else
cat << EOF >> ${DTSPATH}
  orderer${ORDR_ID}.example.com:
    image: hyperledger/fabric-orderer:2.1.0
    container_name: orderer${ORDR_ID}.example.com
EOF
fi
cat << EOF >> ${DTSPATH}
    environment:
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=${EXTERNAL_NETWORK}
      - ORDERER_HOST=orderer${ORDR_ID}.example.com
EOF
if [ "${KF_STR}" != " " ]; then
cat << EOF >> ${DTSPATH}
      - CONFIGTX_ORDERER_ORDERERTYPE=kafka
      - CONFIGTX_ORDERER_KAFKA_BROKERS=${KF_STR}
      - ORDERER_KAFKA_RETRY_SHORTINTERVAL=2s
      - ORDERER_KAFKA_RETRY_SHORTTOTAL=30s
      - ORDERER_KAFKA_VERBOSE=true
EOF
else
cat << EOF >> ${DTSPATH}
      - CONFIGTX_ORDERER_ORDERERTYPE=solo
EOF
fi
cat << EOF >> ${DTSPATH}
      - ORDERER_GENERAL_GENESISPROFILE=${OR_P_NAME}
      - ORDERER_ABSOLUTEMAXBYTES=99 MB
      - ORDERER_PREFERREDMAXBYTES=512 MB
      - ORDERER_HOME=/var/hyperledger/orderer
      - ORDERER_GENERAL_LOGLEVEL=debug
      - ORDERER_GENERAL_LEDGERTYPE=file
      - ORDERER_GENERAL_GENESISMETHOD=file
      - ORDERER_GENERAL_GENESISFILE=/var/hyperledger/orderer/orderer.genesis.block
      - CONFIGTX_ORDERER_BATCHSIZE_MAXMESSAGECOUNT=50
      - CONFIGTX_ORDERER_BATCHTIMEOUT=1s
      - CONFIGTX_ORDERER_ADDRESSES=[127.0.0.1:7050]
      - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
      - ORDERER_GENERAL_LISTENPORT=7050
      - ORDERER_GENERAL_LOCALMSPID=OrdererMSP
      - ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp
      # enabled TLS
      - ORDERER_GENERAL_TLS_ENABLED=true
      - ORDERER_GENERAL_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key
      - ORDERER_GENERAL_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt
      - ORDERER_GENERAL_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
      # - ORDERER_TLS_CLIENTAUTHREQUIRED=false
      # - ORDERER_TLS_CLIENTROOTCAS_FILES=/var/hyperledger/users/Admin@example.com/tls/ca.crt
      # - ORDERER_TLS_CLIENTCERT_FILE=/var/hyperledger/users/Admin@example.com/tls/client.crt
      # - ORDERER_TLS_CLIENTKEY_FILE=/var/hyperledger/users/Admin@example.com/tls/client.key
      - ORDERER_GENERAL_CLUSTER_CLIENTCERTIFICATE=/var/hyperledger/orderer/tls/server.crt
      - ORDERER_GENERAL_CLUSTER_CLIENTPRIVATEKEY=/var/hyperledger/orderer/tls/server.key
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric/orderer
    command: orderer
    volumes:
      - ./genesis.block:/var/hyperledger/orderer/orderer.genesis.block
      - ./crypto-config/ordererOrganizations/example.com/orderers/orderer${ORDR_ID}.example.com/msp:/var/hyperledger/orderer/msp
      - ./crypto-config/ordererOrganizations/example.com/orderers/orderer${ORDR_ID}.example.com/tls/:/var/hyperledger/orderer/tls
      - ./crypto-config/ordererOrganizations/example.com/users:/var/hyperledger/users
      - orderer${ORDR_ID}.example.com:/var/hyperledger/production/orderer
      #- ./ledger/orderer.example.com:/var/hyperledger/production/orderer
    ports:
      - ${port1}:7050
EOF

if [ "${KF_STR}" != " " ];then
cat << EOF >> ${DTSPATH}
    depends_on:
EOF
    for kfs in `seq 0 ${KFS_Count}`
    do
    cat << EOF >> ${DTSPATH}
      - kafka${kfs}
EOF
done
fi
cat << EOF >> ${DTSPATH}
    networks:
      ${EXTERNAL_NETWORK}:
        aliases:
          - orderer${ORDR_ID}.example.com
EOF
}
#addOrderer 1 1000 ext org1 