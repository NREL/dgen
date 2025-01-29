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

# Install dGen as part of the user login for ubuntu
sudo usermod -aG docker ubuntu
cat <<EOF > ~ubuntu/dgen_prune_all_data.sh
docker system prune -a
docker volume prune -f
EOF
chmod 755 ~ubuntu/dgen_prune_all_data.sh

# Create dGen start script
cat <<EOF > ~ubuntu/dgen_start.sh
mkdir -p ~/dgen_data/ && chmod 755 ~/dgen_data/ && chown $(id -un): ~/dgen_data/
cd ~/dgen/docker/
docker-compose up --build -d
docker attach dgen_1
EOF
chmod 755 ~ubuntu/dgen_start.sh

# Add default start path for dgen
echo "cd ~/dgen/docker/" >> ~ubuntu/.bashrc