clear
sudo apt update

apt install -y sqlite3

echo "⚙️ Installing Docker..."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce

echo "⚙️ Installing Docker Compose"
mkdir -p ~/.docker/cli-plugins/
curl -SL https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose


echo "⬇️ Downloading 3x-ui docker-compose.yaml"
curl https://raw.githubusercontent.com/MHSanaei/3x-ui/main/docker-compose.yml -o docker-compose.yaml
docker compose up -d
sleep 1
docker compose down


DB_PATH="db/x-ui.db"
EXTERNAL_IP=$(curl ifconfig.me)


set_panel_username_and_password() {
  echo "👨‍💻 Setting panel username and password..."

  # https://unix.stackexchange.com/a/306107
  PANEL_USERNAME=$(openssl rand -hex 15)

  # https://stackoverflow.com/a/44377013
  #  PANEL_PASSWORD=$(tr -dc 'A-Za-z0-9!?%=' < /dev/urandom | head -c 10)
  PANEL_PASSWORD=$(openssl rand -hex 30)
  printf "UPDATE users SET username='$PANEL_USERNAME', password='$PANEL_PASSWORD' WHERE id = 1" | sqlite3 "$DB_PATH"
}


set_panel_web_path() {
  echo "🌎 Setting panel web path..."

  PANEL_BASE_PATH=$(openssl rand -hex 20)
  printf "INSERT INTO settings (key, value) VALUES ('webBasePath', '/%s/');" "${PANEL_BASE_PATH}" | sqlite3 "$DB_PATH"
}


set_panel_web_port() {
  echo "🌎 Setting panel web port..."

  # https://stackoverflow.com/a/2556282
  PANEL_WEB_PORT=$(shuf -i 65000-65535 -n 1)
  printf "INSERT INTO settings (key, value) VALUES ('webPort', %d);" "${PANEL_WEB_PORT}" | sqlite3 "$DB_PATH"
}

set_panel_https() {
  echo "🔒 Setting panel HTTPS..."

  # https://stackoverflow.com/a/10176685
  openssl req -x509 -newkey rsa:4096 -keyout cert/3x-ui.key -out cert/3x-ui.pem -sha256 -days 3650 -nodes -subj "/L=City"

  printf "INSERT INTO settings (key, value) VALUES ('webCertFile', '/root/cert/3x-ui.pem');" | sqlite3 "$DB_PATH"
  printf "INSERT INTO settings (key, value) VALUES ('webKeyFile', '/root/cert/3x-ui.key');" | sqlite3 "$DB_PATH"
}

set_panel_username_and_password
set_panel_web_path
set_panel_web_port
set_panel_https


docker compose up -d


# https://gist.github.com/loskiq/f6d9348c8cfd8573a90cafda88a57392
openssl x509 -noout -sha256 -fingerprint -in cert/3x-ui.pem

# https://stackoverflow.com/a/8467448
echo -e "\n\n"
echo "https://${EXTERNAL_IP}:${PANEL_WEB_PORT}/${PANEL_BASE_PATH}"
echo "Username: ${PANEL_USERNAME}"
echo "Password: ${PANEL_PASSWORD}"
