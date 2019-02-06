#!/bin/bash
BROWN='\033[0;33m'
NC='\033[0m'
GREEN='\033[0;32m'
org_pth=""
EXT_NW=""
D_STK=""
#declare -A orgs
function sendTokenToOrgs() {
    ./dockerSetup.sh "sendJoinToken" ${orgs[@]}
}
function startSwarmNetwork() {
    Cr_D=$PWD
    cd $1
    EXT_NW=$2
    orgs=("${@:3}")
    chmod +x ./dockerSetup.sh 
    chmod +x ./buildingNetwork.sh
    ./dockerSetup.sh "swarmCreate" ${EXT_NW}
    #sendTokenToOrgs
  cd $Cr_D
}

function startComposeNetwork () {
    Cr_D=$PWD
    EXT_NW=$2
    cd $1
    chmod +x ./dockerSetup.sh 
    chmod +x ./buildingNetwork.sh
    ./dockerSetup.sh "deployCompose" ${EXT_NW}
    #sendTokenToOrgs
    cd $Cr_D
}
function startService() {
    Cr_D=$PWD
    cd $org_pth
    chmod +x ./dockerSetup.sh 
    ./dockerSetup.sh "deployServices" ${D_STK}
    cd $Cr_D
}
function startCompose() {
    Cr_D=$PWD
    cd $org_pth
    chmod +x ./dockerSetup.sh 
    export COMPOSE_PROJECT_NAME=clif
    ./dockerSetup.sh "deployCompose" $EXT_NW
    cd $Cr_D
}
function deployNetwork() {
    CLI_CONTAINER=$(docker ps |grep ${D_NME}_cli|awk '{print $1}')
    if [ "${CLI_CONTAINER}" == "" ]; then
    echo -e "${RED}CONTAINER NOT found !!! ${NC}"
    exit 1
    fi
    docker exec ${CLI_CONTAINER} ./buildingNetwork.sh $CH_NME $D_NME $CC_S_P $CC_VER $P_CT false
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! failed"
        exit 1
    fi
}
function instantiateChainIntoChannel() {
    echo $@
    CH_NME=$1
    D_NME=$2
    CC_S_P=github.com/chaincode/chaincode_example02/go/
    CC_VER=$3
    P_CT=$4
    POLICY=$5
    # -P "OR ('Org1MSP.peer','Org2MSP.peer')"
    CLI_CONTAINER=$(docker ps |grep ${D_NME}_cli|awk '{print $1}')
    if [ "${CLI_CONTAINER}" == "" ]; then
    echo -e "${RED}CONTAINER NOT found !!! ${NC}"
    exit 1
    fi
    docker exec ${CLI_CONTAINER} ./buildingNetwork.sh $CH_NME $D_NME $CC_S_P $CC_VER $P_CT true "$POLICY"
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! failed"
        exit 1
    fi
}
function runMainNetwork() {
    echo $@
    org_pth=$1
    EXT_NW=$2
    D_STK=$9
    CH_NME=$3
    D_NME=$4
    CC_S_P=github.com/chaincode/chaincode_example02/go/
    CC_VER=$5
    ORD_adr=$6
    P_CT=$7
    n_tpe=$8
    #startSwarmNetwork
    echo ${n_tpe}
    if [ "${n_tpe}" == "Docker-compose" ]; then
        echo "Starting Compose Network "
    else
        startService
    fi
    deployNetwork
}
function sendOrderer() {
    if [ "$3" == "Docker-swarm-m" ]; then
        scp -r ~/CLIF/$1/crypto-config/ordererOrganizations $4:./CLIF/$2/crypto-config/
    else
        cp -rf ~/CLIF/$1/crypto-config/ordererOrganizations ~/CLIF/$2/crypto-config/
    fi
}
function addNewOrg() {
    M_ORG=$1
    ad_Org=$2
    CH_NME=$3
    O_TPE=$4
    AP_cnt=$5
    DEP_TYPE=$6
    OG_SSH_ADD=$7
    if [ ! -f "${ad_Org}.json" ]; then
        if [ "$DEP_TYPE" == "Docker-swarm-m" ]; then
            scp $OG_SSH_ADD:./CLIF/$ad_Org/${ad_Org}.json ~/CLIF/${M_ORG}/
            sendOrderer $M_ORG $ad_Org $DEP_TYPE $OG_SSH_ADD
        else
            cp ~/CLIF/${ad_Org}/${ad_Org}.json ~/CLIF/${M_ORG}/
            sendOrderer $M_ORG $ad_Org
        fi
    fi
    CLI_CONTAINER=$(docker ps |grep ${M_ORG}_cli|awk '{print $1}')
    if [ "${CLI_CONTAINER}" == "" ]; then
    echo -e "${RED}CONTAINER NOT found !!! ${NC}"
    exit 1
    fi
    docker exec ${CLI_CONTAINER} ./addNewOrg.sh $ad_Org $CH_NME $O_TPE $AP_cnt $M_ORG
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! failed"
        exit 1
    fi
}

function AddOrgToNetwork() {
    echo $@
    ad_Org=$1
    CH_NME=$2
    O_TPE=$3
    CC_NAME=$4
    CC_VER=$5
    N_TYPE=$6
    EXT_NW=$7
    DS_NAME=$9
    if [ "${O_TPE}" == "KAFKA" ]; then
        OR_AD="orderer0"
    else
        OR_AD="orderer0"
    fi
    AP_CN=$8
    OG_SSH_ADD=${10}
    M_OG=${11}
    if [ "$N_TYPE" == "Docker-swarm-m" ]; then
        echo ""buildNetwork" ${DS_NAME} ${ad_Org} ${CH_NME} ${CC_NAME} ${CC_VER} ${OR_AD} "github.com/chaincode/chaincode_example02/go/" $AP_CN $N_TYPE $EXT_NW"
        scp ~/CLIF/$M_OG/tokenToJoinNetwork.sh $OG_SSH_ADD:./CLIF/$ad_Org/
        ssh $OG_SSH_ADD /bin/bash << EOF
cd ./CLIF/$ad_Org/;
chmod +x tokenToJoinNetwork.sh;
./tokenToJoinNetwork.sh;
./dockerSetup.sh "buildNetwork" $EXT_NW ${ad_Org} ${CH_NME} ${CC_NAME} ${CC_VER} ${OR_AD} "github.com/chaincode/chaincode_example02/go/" $AP_CN $N_TYPE ${DS_NAME}
EOF
    else
        c_path=$PWD
        cd ~/CLIF/${ad_Org}/
        echo ""buildNetwork" ${DS_NAME} ${ad_Org} ${CH_NME} ${CC_NAME} ${CC_VER} ${OR_AD} "github.com/chaincode/chaincode_example02/go/" $AP_CN $N_TYPE $EXT_NW"
        export COMPOSE_PROJECT_NAME=clif
        ./dockerSetup.sh "buildNetwork" $EXT_NW ${ad_Org} ${CH_NME} ${CC_NAME} ${CC_VER} ${OR_AD} "github.com/chaincode/chaincode_example02/go/" $AP_CN $N_TYPE ${DS_NAME}
        cd $c_path
    fi
}
function updateChannelConfig() {
    m_org=$1
    ad_org=$2
    CH_NME=$3
    DN_TYPE=$4
    DN_ORG_SSH=$5
    tr="$"
    cat << EOF > ./updateChannelConfig.sh
#!/bin/bash
CHANNEL_NAME=${tr}2
DOMAIN=${tr}1
ORDERER_URL=orderer0.example.com
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
peer channel update -f ${tr}{DOMAIN}_update_in_envelope.pb -c ${tr}CHANNEL_NAME -o ${tr}ORDERER_URL:7050 --tls --cafile ${tr}ORDERER_CA 2>&1
if [ ${tr}? -ne 0 ];then
  echo "******************** FAILED TO ADD ${tr}DOMAIN INTO THE NETWORK *********************"
  exit 1
else
  echo "******************** ${tr}{DOMAIN} ORGANISATION ADDED TO NETWORK **********************"
fi
exit 0
EOF
echo "DN_ORG_SSH=${DN_ORG_SSH}"
chmod +x ./updateChannelConfig.sh
    if [ "${DN_ORG_SSH}" != "" ]; then
        scp ./updateChannelConfig.sh $DN_ORG_SSH:./CLIF/$m_org/
        rm ./updateChannelConfig.sh
        scp ./updateChannelConfig.sh $DN_ORG_SSH:./CLIF/$m_org/
        M_C_ID=$(ssh $DN_ORG_SSH docker ps|grep ${m_org}_cli|awk '{print $1}')
        echo $M_C_ID
        ssh $DN_ORG_SSH /bin/bash << EOF
docker exec $M_C_ID ./updateChannelConfig.sh $ad_Org $CH_NME;
EOF
   else
        cp ./updateChannelConfig.sh ~/CLIF/${m_org}/
        rm ./updateChannelConfig.sh
        CLI_CONTAINER=$(docker ps |grep ${m_org}_cli|awk '{print $1}')
        if [ "${CLI_CONTAINER}" == "" ]; then
            echo -e "${RED}CONTAINER NOT found !!! ${NC}"
            exit 1
        fi
        docker exec ${CLI_CONTAINER} ./updateChannelConfig.sh $ad_Org $CH_NME
        if [ $? -ne 0 ]; then
            echo -e "${RED}ERROR !!!! failed to add organisation${NC}"
            exit 1
        fi
    fi
}

function signChannelConfig() {
    m_org=$1
    ad_org=$2
    CH_NME=$3
    sin_org=$4
    p_cnt=$5
    DN_TYPE=$6
    DN_ORG_SSH=$8
    ROOT_ORG=$7
    tr="$"
    cat << EOF > ./signChannelConfig.sh
#!/bin/bash
P_CN=${tr}1
M_DMIN=${tr}2
DOMAIN=${tr}3
peer=0
while [ "${tr}peer" != "${tr}P_CN" ]
do
    export CORE_PEER_ADDRESS=peer${tr}peer.${tr}{M_DMIN}.example.com:7051
    peer channel signconfigtx -f ${tr}{DOMAIN}_update_in_envelope.pb
    peer=${tr}(expr ${tr}peer + 1)
done
export CORE_PEER_ADDRESS=peer0.${tr}{M_DMIN}.example.com:7051
exit 0
EOF
chmod +x ./signChannelConfig.sh
d_pth=/opt/gopath/src/github.com/hyperledger/fabric/peer/
if [ "${DN_ORG_SSH}" != "" ]; then
   scp ./signChannelConfig.sh $DN_ORG_SSH:./CLIF/$ad_org/
    rm ./signChannelConfig.sh
    R_C_ID=$(docker ps |grep ${ROOT_ORG}_cli|awk '{print $1}')
    docker cp $R_C_ID:$d_pth/${sin_org}_update_in_envelope.pb ~/CLIF/${ROOT_ORG}/${sin_org}_update_in_envelope.pb
    scp ~/CLIF/${ROOT_ORG}/${sin_org}_update_in_envelope.pb $DN_ORG_SSH:./CLIF/${ad_org}/${sin_org}_update_in_envelope.pb
    M_C_ID=$(ssh $DN_ORG_SSH docker ps|grep ${ad_org}_cli|awk '{print $1}')
    echo $M_C_ID    
    ssh $DN_ORG_SSH /bin/bash << EOF
docker cp ~/CLIF/${ad_org}/${sin_org}_update_in_envelope.pb $M_C_ID:$d_pth/${sin_org}_update_in_envelope.pb
EOF
    ssh $DN_ORG_SSH /bin/bash << EOF
docker exec ${M_C_ID} ./signChannelConfig.sh $p_cnt $ad_org $sin_org;
docker cp $M_C_ID:$d_pth/${sin_org}_update_in_envelope.pb  ./CLIF/${ad_org}/${sin_org}_update_in_envelope.pb
EOF
    rm -f ~/CLIF/${ROOT_ORG}/${sin_org}_update_in_envelope.pb
    scp $DN_ORG_SSH:./CLIF/${ad_org}/${sin_org}_update_in_envelope.pb ~/CLIF/${ROOT_ORG}/${sin_org}_update_in_envelope.pb
else

cp ./signChannelConfig.sh ~/CLIF/$ad_org/
rm ./signChannelConfig.sh
M_C_ID=$(docker ps |grep ${m_org}_cli|awk '{print $1}')
 if [ "${M_C_ID}" == "" ]; then
    echo -e "${RED}CONTAINER NOT found !!! ${NC}"
    exit 1
fi
A_C_ID=$(docker ps |grep ${ad_org}_cli|awk '{print $1}')
 if [ "${A_C_ID}" == "" ]; then
    echo -e "${RED}CONTAINER NOT found !!! ${NC}"
    exit 1
fi
docker cp $M_C_ID:$d_pth/${sin_org}_update_in_envelope.pb ~/CLIF/${m_org}/${sin_org}_update_in_envelope.pb
docker cp ~/CLIF/${m_org}/${sin_org}_update_in_envelope.pb $A_C_ID:$d_pth 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! failed"
        exit 1
    fi
docker exec ${A_C_ID} ./signChannelConfig.sh $p_cnt $ad_org $sin_org
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! failed"
        exit 1
    fi
fi
}
