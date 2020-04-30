class VersionError(Exception):
    pass

class UninstalledError(Exception):
    pass

def check_dependencies():

    f = open('requirements.txt', 'r')
    requirements = [l.replace('\n', '') for l in f.readlines()]
    f.close()
    for requirement in requirements:
        if '=' in requirement:
            package, version = requirement.split('=')
        else:
            package, version = [requirement, '']

        # try to load the package
        try:
            installed = __import__(package)
        except:
            raise UninstalledError('{0} is not installed.'.format(package))
        # check the version
        if version != '':
            if version != installed.__version__:
                raise VersionError(
                    'Version for {0} is not equal to {1}'.format(package, version))
