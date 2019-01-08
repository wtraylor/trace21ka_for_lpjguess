from zipfile import ZipFile


def unzip(filename, targetdir):
    """Decompress a zip file into a target directory."""
    with ZipFile(filename, "r") as zip_ref:
        zip_ref.extractall(targetdir)
