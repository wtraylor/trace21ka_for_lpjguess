from termcolor import cprint
from zipfile import ZipFile


def unzip(filename, targetdir):
    """Decompress a zip file into a target directory."""
    cprint("Unzipping '%s' into '%s'..." % (filename, targetdir))
    with ZipFile(filename, "r") as zip_ref:
        zip_ref.extractall(targetdir)
