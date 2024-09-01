clear

# https://stackoverflow.com/a/10176685
openssl req -x509 -newkey rsa:4096 -keyout cert/3x-ui.key -out cert/3x-ui.pem -sha256 -days 3650 -nodes -subj "/L=City"
# https://gist.github.com/loskiq/f6d9348c8cfd8573a90cafda88a57392
openssl x509 -noout -sha256 -fingerprint -in cert/3x-ui.pem

docker compose down
python3 setup_panel.py
docker compose up -d
