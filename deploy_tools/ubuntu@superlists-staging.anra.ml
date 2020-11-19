from fabric.contrib.files import append, exists, sed
from fabric.api import env, local, run, sudo
import random

env.key_filename = '~/.ssh/id_rsa'

REPO_URL = 'https://github.com/anra-dev/new_telebot.git'

def test_foo():
    run(f'touch /home/{env.user}/1.test')

def deploy():
    """развернуть"""
    site_folder = f'/home/{env.user}/sites/{env.host}'
    source_folder = site_folder + '/source'
    _create_directory_structure_if_necessary(site_folder)
    _get_latest_source(source_folder)
    _updata_settings(source_folder, env.host)
    _updata_virtualenv(source_folder)
    _updata_static_files(source_folder)
    _updata_database(source_folder)

def _create_directory_structure_if_necessary(site_folder):
    """создает структуру каталогов если нужно"""
    for subfolder in ('database', 'static', 'virtualenv', 'source'):
        sudo(f'mkdir -p {site_folder}/{subfolder}')

def _get_latest_source(source_folder):
    """получить самый свежий исходный код"""
    if exists(source_folder + '/.git'):
        run(f'cd{source_folder} && fetch')
    else:
        rin(f'git clone {REPO_URL} {source_folder}')
    current_commit = local("git log -n 1 --format=%H", capture=True)
    run(f'cd {source_folder} && git reset --hard {current_commit}')

def _updata_settings(source_folder, site_name):
    """обновить настройки"""
    settings_path = source_folder + 'superlists/settings.py'
    sed(settings_path, "DEBUG = True", "DEBUG = False")
    sed(settings_path,
        'ALLOWED_HOSTS =.+$',
        f'ALLOWED_HOSTS =[{site_name}]'
    )
    secret_key_file = source_folder + '/superlists/secret_key.py'
    if not exists(secret_key_file):
        chars = 'abcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*(-_=+)'
        key = ''.join(random.Systemrandom().choice(chars) for _ in range(50))
        append(secret_key_file, f'SECRET_KEY = "{key}"')
    append(settings_path, '\nfrom .secret_key import SECRET_KEY')

def _updata_virtualenv(source_folder):
    """обновить виртуальную среду"""
    virtualenv_folder = source_folder + '/../virtualenv'
    if not exists(virtualenv_folder + 'bin/pip'):
        run(f'python3 -m venv {virtualenv_folder}')
    run(f'virtualenv_folder/bin/pip install - r {source_folder}/requirements.txt')

def _updata_static_files(source_folder):
    """обновить статические файлы"""
    run(f'cd {source_folder} && ../virtualenv/bin/python manage.py collectstatic --noinput')

def _updata_database(source_folder):
    """обновить базу данных"""
    run(f'cd {source_folder} && ../virtualenv/bin/python manage.py migrate --noinput')
