#!/bin/bash

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y

# Install Docker Engine
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose -y

# Setup /data directory, 999 is the container users
mkdir -p ~ubuntu/dgen_data/
chown ubuntu:999 ~ubuntu/dgen_data/
chmod 770 ~ubuntu/dgen_data/

# Install dGen as part of the user login for ubuntu
sudo usermod -aG docker ubuntu
cat <<EOF > ~ubuntu/dgen_prune_all_data.sh
docker system prune -a
docker volume prune -f
EOF
chmod 755 ~ubuntu/dgen_prune_all_data.sh

# Create dGen start script
cat <<EOF > ~ubuntu/dgen_start.sh
cd ~/dgen/docker/
docker-compose up --build -d
docker attach dgen_1
EOF
chmod 755 ~ubuntu/dgen_start.sh

# Add default start path for dgen
echo "cd ~/dgen/docker/" >> ~ubuntu/.bashrc

# Add dgen usage to login message
echo -e "\e[1;32mTo launch dgen run:\e[0m \e[1;36msource ~/dgen_start.sh\e[0m" | sudo tee -a /etc/motd

# Disable Hyperthreading
printf '#!/bin/bash\nfor cpunum in $(cat /sys/devices/system/cpu/cpu*/topology/thread_siblings_list | cut -s -d, -f2- | tr ',' '\n' | sort -un); do echo 0 > /sys/devices/system/cpu/cpu$cpunum/online; done' > /usr/local/bin/disable-ht.sh
chmod 755 /usr/local/bin/disable-ht.sh
chown root:root /usr/local/bin/disable-ht.sh
cat <<EOF >/etc/systemd/system/disable-ht.service
          [Unit]
          Description=Disable Hyperthreading
          After=multi-user.target
          DefaultDependencies=no

          [Service]
          Type=oneshot
          ExecStart=/usr/local/bin/disable-ht.sh
          RemainAfterExit=yes
          User=root

          [Install]
          WantedBy=multi-user.target
EOF
chmod 0644 /etc/systemd/system/disable-ht.service
chown root:root /etc/systemd/system/disable-ht.service
systemctl daemon-reexec
systemctl enable disable-ht.service
systemctl start disable-ht.service