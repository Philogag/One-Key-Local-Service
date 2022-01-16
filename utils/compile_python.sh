#!/bin/bash

# 一键编译并安装python

######################################## Config ###########################################

PYTHON_VERSION=3.9.9
DOWNLOAD_MIRROR="https://repo.huaweicloud.com/python"

SOURCE_PATH="/opt/python/src"
INSTALL_PATH="/opt/python/python-$PYTHON_VERSION"

COMPILE_THREAD=4

DOWNLOAD_URI="$DOWNLOAD_MIRROR/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz"

######################################## Super Echo ###########################################
IFS=$'\n'
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

  return $?
}

######################################## Tool Functions ###########################################

get_os_type(){
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

prepare_gcc(){
  super_echo "Install gcc and libs."
  if [ $? -eq 1 ]; then 
    return;
  fi
  case $SYSTEM_INFO in 
  "Deepin:15.11" | "Deepin:20" | "Ubuntu:20.04" | "Ubuntu:18.04" | "Debian:9" | "Debian:10")
    # apt-get -y install curl software-properties-common apt-transport-https
    # apt-get -y install python3 python3-pip
    ;;
  "CentOS:7")
    yum install -y centos-release-scl-rh
    yum install -y devtoolset-8-gcc devtoolset-8-gcc-c++
    source /opt/rh/devtoolset-8/enable
    yum install -y \
      zlib-devel \
      bzip2-devel \
      openssl-devel \
      ncurses-devel \
      sqlite-devel \
      readline-devel \
      tk-devel \
      libffi-devel \
      make
    ;;
  esac

  gcc --version
  g++ --version
}

download_src() {
  super_echo "Download python source package."
  if [ $? -eq 1 ]; then 
    return;
  fi

  if [ ! -d $SOURCE_PATH ]; then 
    mkdir -p $SOURCE_PATH
  fi
  
  cd $SOURCE_PATH

  if [ -d Python-$PYTHON_VERSION ]; then 
    echo Skip.
    cd Python-$PYTHON_VERSION
    return
  fi

  wget $DOWNLOAD_URI

  tar -xf Python-$PYTHON_VERSION.tgz
  rm Python-$PYTHON_VERSION.tgz
  cd Python-$PYTHON_VERSION
}

compile() {
  ./configure \
    --prefix=$INSTALL_PATH \
    --with-ssl \
    --enable-shared \
    --enable-optimizations
  
  make -j$COMPILE_THREAD
  make install
}

make_link() {
  # ln -s $INSTALL_PATH/
  echo ''
}

######################################## Main ###########################################
main(){
  get_os_type

  super_echo "Hello.
  Welcome Use the Auto Python Build & Install Script.
  
  ---Your System is \"$SYSTEM_INFO\"---"

  check_root

  prepare_gcc
  download_src
  compile
  make_link

  exit 0;
}

main $*
