#!/bin/bash

set -e

echo "Waiting until cloud-init initializes"
cloud-init status --wait || true

export DEBIAN_FRONTEND=noninteractive

disable_apt_daily_timers() {
    echo "Stopping APT daily timers"
    systemctl stop apt-daily.timer || true
    systemctl stop apt-daily-upgrade.timer || true

    while fuser /var/lib/dpkg/lock >/dev/null 2>&1;
    do
        echo "DPKG is locked, waiting..."
        sleep 1
    done
}

enable_apt_daily_timers() {
    echo "Starting APT daily timers"
    systemctl start apt-daily-upgrade.timer || true
    systemctl start apt-daily.timer || true
}

. /etc/os-release

read -ra OS_ID_LIST <<< "$ID_LIKE"

# GamePanel does not have $ID_LIKE
if [ ${#OS_ID_LIST[@]} -eq 0 ];
then
  echo "WARNING: \$ID_LIKE variable is empty, falling back to \$ID"
  OS_ID_LIST=("$ID")
fi

if [ ${#OS_ID_LIST[@]} -eq 0 ];
then
  echo "ERROR: Looks like OS not supported"
  cat /etc/os-release
  exit 2
fi

for os in "${OS_ID_LIST[@]}";
do
  if [ "$os" = "debian" ];
  then
    echo "Debian / Ubuntu OS detected"

    disable_apt_daily_timers

    echo "Installing required packages"
    apt -qqy clean
    apt -qqy update
    apt -qqy install gnupg

    if [[ "$VERSION" =~ ^2[234].* ]];
    then
      echo "Adding GPG key"
      wget -qO - https://repository.monarx.com/repository/monarx/publickey/monarxpub.gpg | sudo tee /etc/apt/trusted.gpg.d/monarx.asc
    else
      echo "Adding deprecated GPG key"
      apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4E240071023138C8
    fi

    echo "Adding repository"
    echo "deb [arch=amd64] https://repository.monarx.com/repository/$ID-$VERSION_CODENAME/ $VERSION_CODENAME main" > /etc/apt/sources.list.d/monarx.list

    echo "Updating packages"
    apt -qqy update 1>/dev/null 2>&1 || true

    echo "Installing Monarx"
    apt -qqy install monarx-protect-autodetect 1>/dev/null 2>&1

    enable_apt_daily_timers

    break
  fi

  if [ "$os" = "centos" ];
  then
    echo "CentOS / CentOS-like OS detected"

    echo "Adding repository"
    case $PLATFORM_ID in
      platform:el7)
        curl -so /etc/yum.repos.d/monarx.repo https://repository.monarx.com/repository/monarx-yum/linux/yum/el/7/x86_64/monarx.repo
        ;;

      platform:el8)
        curl -so /etc/yum.repos.d/monarx.repo https://repository.monarx.com/repository/monarx-yum/linux/yum/el/8/x86_64/monarx.repo
        ;;

      platform:el9)
        curl -so /etc/yum.repos.d/monarx.repo https://repository.monarx.com/repository/monarx-yum/linux/yum/el/9/x86_64/monarx.repo
        ;;
    esac

    echo "Adding GPG key"
    rpm --import https://repository.monarx.com/repository/monarx/publickey/monarxpub.gpg || true

    echo "Installing Monarx"
    yum install monarx-protect-autodetect -y --disablerepo=* --enablerepo=monarx 1>/dev/null 2>&1
    break
  fi
done

echo "Looking for Monarx agent config"
stat /etc/monarx-agent.conf 2>&1

echo "Checking if Monarx agent is installed"
monarx-agent --help

echo "Starting Monarx agent"
systemctl restart monarx-agent.service
