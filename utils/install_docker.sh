#!/bin/bash

######################################## Super Echo ###########################################
IFS=$'\n'
pause_and_ask(){
  if [ -n "$1" -o $no_ask -eq 1 ]; then
    return 0;
  fi
  echo -e "Do you want to continue? [Y(yes), s(skip), n(exit)]: \c"
  read FLAG

  case $FLAG in
  Y | y | "")
    return 0;;
  n | N)
    exit 0;;
  s | S)
    return 1;;
  *)
    exit 0;;
  esac
}
echo_center()
{
  WINDWO_WIDE=`stty size|awk '{print $2}'`
  len=${#1}
  w=`expr $WINDWO_WIDE - $len`
  w=`expr $w / 2`
  if [ $w -ge '1' ]; then
    spaces=`yes " " | sed $w'q' | tr -d '\n'`
  else
    spaces=""
  fi
  echo "${spaces}${1}"
}
super_echo()
{
  WINDWO_WIDE=`stty size|awk '{print $2}'`
  line=`yes "-" | sed $WINDWO_WIDE'q' | tr -d '\n'`
  echo $line
  echo ""
  for i in ${1}
  do 
    echo_center $i
  done
  echo ""
  echo $line

  pause_and_ask $2
  return $?
}

######################################## Tool Functions ###########################################
no_ask=1
get_args(){
  case "$1" in
    "--no-ask") no_ask=1;;
  esac

  if [ $no_ask -eq 0 ]; then
    super_echo "You can use \"--no-ask\" argument to skip all the asks." --no-ask
  fi
}

get_os_type(){
  # info=`cat /etc/os-release`
  # for i in ${info[@]}
  # do 
  #   case ${i%%=*} in
  #   NAME)
  #     os_type=`echo ${i#*=} | tr -d \"`
  #     ;;
  #   VERSION_ID)
  #     os_version=`echo ${i#*=} | tr -d \"`
  #     ;;
  #   esac
  # done
  os_type=`cat /etc/os-release | grep ^NAME | awk -v FS== '{print $2}' | tr -d \" | awk '{print $1}'`
  os_version=`cat /etc/os-release | grep ^VERSION_ID | awk -v FS== '{print $2}' | tr -d \" | awk '{print $1}'`
  SYSTEM_INFO=$os_type:$os_version
}

check_root(){
  touch /root/tryroot 1>/dev/null 2>/dev/null
  if [ $? -ne 0 ]; then 
    super_echo "You are not running in SuperAdmin.
Please retry with \"sudo\" or switch to user \"root\"." --no-ask
    exit 0
  fi
  rm -rf /root/tryroot 1>/dev/null 2>/dev/null
}

######################################## Installer Functions ###########################################
install_pre(){
  super_echo "Install dependency tools."
  if [ $? -eq 1 ]; then 
    return;
  fi
  case $SYSTEM_INFO in 
  "Deepin:15.11" | "Deepin:20" | "Ubuntu:20.04" | "Ubuntu:18.04" | "Debian:9" | "Debian:10" | "Debian:11")
    apt-get -y install curl software-properties-common apt-transport-https
    apt-get -y install python3 python3-pip
    ;;
  "CentOS:7")
    yum -y install curl wget
    yum -y install python3 python3-pip
    ;;
  esac
}

install_docker(){
  super_echo "Install Docker."
  if [ $? -eq 1 ]; then 
    return;
  fi
  case $SYSTEM_INFO in 
  "Deepin:15.11" | "Debian:9")
    echo -e "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/debian stretch stable" > /etc/apt/sources.list.d/docker.list
    curl -fsSL "https://mirrors.ustc.edu.cn/docker-ce/linux/debian/gpg" | apt-key add -
    apt-get update && apt-get install -y docker-ce
    ;;
  "Deepin:20" | "Debian:10")
    echo -e "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/debian buster stable" > /etc/apt/sources.list.d/docker.list
    curl -fsSL "https://mirrors.ustc.edu.cn/docker-ce/linux/debian/gpg" | apt-key add -
    apt-get update && apt-get install -y docker-ce
    ;;
  "Debian:11")
    echo -e "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/debian bullseye stable" > /etc/apt/sources.list.d/docker.list
    curl -fsSL "https://mirrors.ustc.edu.cn/docker-ce/linux/debian/gpg" | apt-key add -
    apt-get update && apt-get install -y docker-ce
    ;;
  "CentOS:7")
    yum install -y yum-utils device-mapper-persistent-data lvm2
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

    yum-config-manager --disable docker-ce-edge 1>/dev/null 2>/dev/null
    yum-config-manager --disable docker-ce-test 1>/dev/null 2>/dev/null

    yum install docker-ce -y
    ;;
  "Ubuntu:20.04" | "Ubuntu:18.04")
    echo "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu bionic stable" > /etc/apt/sources.list.d/docker.list
    curl -fsSL "https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/gpg" | apt-key add -
    apt-get update && apt-get install -y docker-ce
    ;;
  esac
}

config_docker(){
  super_echo "Enable docker"
  if [ $? -eq 1 ]; then 
    return;
  fi
  echo -e "{\n  \"registry-mirrors\": [\"http://hub-mirror.c.163.com\"]\n}" >daemon.json
  mkdir -p /etc/docker
  mv daemon.json /etc/docker/daemon.json
  systemctl daemon-reload
  systemctl start docker
  systemctl enable docker
  echo ""
  docker version
  # sudo systemctl status docker
}

config_pip(){
  super_echo "Link pip to tuna.tsinghua.edu.cn"
  if [ $? -eq 1 ]; then 
    return;
  fi
  rm -rf ~/.pip
  mkdir -p ~/.pip/
  echo -e "[global]\nindex-url = https://pypi.tuna.tsinghua.edu.cn/simple" > ~/.pip/pip.conf
  python3 -m pip install pip --upgrade
  echo ok
}

install_docker_compose(){
  super_echo "Install docker-compose"
  if [ $? -eq 1 ]; then 
    return;
  fi
  pip3 install docker-compose
  rm -f /bin/docker-compose
  ln -s /usr/local/bin/docker-compose /bin/docker-compose
  echo ""
  super_echo `docker-compose --version`
}

######################################## Main ###########################################
main(){
  get_os_type

  super_echo "Hello.
  Welcome Use the Auto Docker & Docker-compose Install Script.
  
  ---Your System is \"$SYSTEM_INFO\"---" --no-ask

  check_root
  get_args $*

  install_pre
  install_docker
  config_docker
  config_pip
  install_docker_compose

  exit 0;
}

main $*
