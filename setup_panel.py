import random
import sqlite3
import string
import urllib.request

connection = sqlite3.connect("db/x-ui.db")
cursor = connection.cursor()

settings = dict()


# https://stackoverflow.com/a/2257449
def generate_random_string(length: int = 10, special_symbols: bool = True) -> str:
    alphabet = string.ascii_letters + string.digits + (string.punctuation if special_symbols else "")
    return ''.join(random.choice(alphabet) for _ in range(length))


def get_external_ip():
    settings["external_ip"] = urllib.request.urlopen('http://ifconfig.me').read().decode('utf8')


def setup_username_and_password():
    username = generate_random_string(length=10, special_symbols=False).upper()
    password = generate_random_string(length=40)

    sql = f'UPDATE users SET username=?, password=? WHERE id = 1'
    values = [username, password]

    cursor.execute(sql, values)
    connection.commit()

    print(f"\n\n\nUsername: {username}\nPassword: {password}")


def setup_panel_port():
    panel_port = 60000 + random.randrange(5535)
    sql = f'UPDATE settings SET value={panel_port} WHERE key = "webPort"'

    cursor.execute(sql)
    connection.commit()

    settings["panel_port"] = panel_port


def setup_https():
    sql = f'UPDATE settings SET value="/root/cert/3x-ui.pem" WHERE key = "webCertFile"'
    cursor.execute(sql)

    sql = f'UPDATE settings SET value="/root/cert/3x-ui.key" WHERE key = "webKeyFile"'
    cursor.execute(sql)

    connection.commit()


def setup_web_base_path():
    web_base_path = generate_random_string(length=30, special_symbols=False)
    sql = f'UPDATE settings SET value="/{web_base_path}/" WHERE key = "webBasePath"'

    cursor.execute(sql)
    connection.commit()

    print(f"https://{settings['external_ip']}:{settings['panel_port']}/{web_base_path}\n\n\n")


if __name__ == "__main__":
    get_external_ip()
    setup_username_and_password()
    setup_panel_port()
    setup_https()
    setup_web_base_path()
