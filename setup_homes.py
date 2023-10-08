import os
import subprocess
from subprocess import Popen, PIPE
import argparse


IGNORE_FILES = [
    'du-cesnet',
    'software',
    'software.metacentrum.cz',
    'singularity.metacentrum.cz',
    'projects',
    'ostrava2-archive'
]

STORAGE_PATH = '/storage'



def install(home):
    res = subprocess.run(['mkdir', 'tools'], text=True, capture_output=True)
    print(f'mkdir tools -> {res.returncode}')

    os.putenv("HOME", home)
    os.chdir(f'{home}/tools')
    print(f'cd tools')

    res = subprocess.run(['git', 'clone', 'https://github.com/fpartl/metaenv.git'], text=True, capture_output=True)
    print(f'git clone -> {res.returncode}')

    os.chdir(f'{home}/tools/metaenv')
    print('cd metaenv')

    res = subprocess.run(['chmod', '+x', 'install.sh'], text=True, capture_output=True)
    print(f'chmod +x install.sh -> {res.returncode}')

    process = Popen(['./install.sh'], text=True, stdin=PIPE, stdout=PIPE, stderr=PIPE)
    out, err = process.communicate()
    print(f'./install.sh -> {res.returncode}')
    print('install.sh log: ')
    print(out)



def update(home):
    os.putenv("HOME", home)
    os.chdir(f'{home}/tools/metaenv')
    print('cd tools/metaenv')

    res = subprocess.run(['git', 'fetch'], text=True, capture_output=True)
    print(f'git fetch -> {res.returncode}')

    res = subprocess.run(['git', 'reset', '--hard', 'FETCH_HEAD'], text=True, capture_output=True)
    print(f'git reset --hard FETCH_HEAD -> {res.returncode}')

    process = Popen(['./install.sh'], text=True, stdin=PIPE, stdout=PIPE, stderr=PIPE)
    out, err = process.communicate()
    print(f'./install.sh -> {res.returncode}')
    print('install.sh log: ')
    print(out)



def main():
    username = os.environ['LOGNAME']
    current_home = os.environ['HOME']
    print(f'LOGNAME={username}')

    storages = os.listdir(STORAGE_PATH)
    for ignore_file in IGNORE_FILES:
        storages.remove(ignore_file)

    if args['update']:
        print('Running update')
    
    for storage in storages:
        home = f'{STORAGE_PATH}/{storage}/home/{username}'
        if not os.path.exists(home):
            print(f'No home directory found, skipping {storage}')
            continue
        
        os.chdir(home)

        if not args['update']:
            print(f'Setting up {storage}')
            install(home)
        else:
            if not os.path.exists(f'{home}/tools/metaenv'):
                print(f'metaenv directory not found on storage {storage}, running install')
                #install(home)
            else:
                print(f'Updating {storage}')
                update(home)

    
    os.putenv("HOME", current_home)
    os.chdir(current_home)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--update', default=False, required=False)
    args = vars(parser.parse_args())
    main()