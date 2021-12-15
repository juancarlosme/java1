import os
import zipfile
import io
import argparse

def process_jarfile_content(zf, filetree):
    '''

    Recursively look in zf for the class of interest or more jar files
    Print the hits
    zf is a zipfile.ZipFile object
    '''
    for f in zf.namelist():
        if os.path.basename(f) == 'JndiLookup.class':
            # found one, print it
            filetree_str = ' contains '.join(filetree)
            print(filetree_str,'contains "JndiLookup.class"')
        elif os.path.basename(f).lower().endswith(".jar") or os.path.basename(f).lower().endswith(".war") or os.path.basename(f).lower().endswith(".ear"):
            # keep diving
            try:
                new_zf = zipfile.ZipFile(io.BytesIO(zf.read(f)))
            except:
                continue
            new_ft = list(filetree)
            new_ft.append(f)
            process_jarfile_content(new_zf, new_ft)


def do_jarfile_from_disk(fpath):
    try:
        zf = zipfile.ZipFile(fpath)
    except:
        return
    process_jarfile_content(zf, filetree=[fpath,])


def main(topdir):
    for root, dirs, files in os.walk(topdir, topdown=False):
        for name in files:
            if not (name.lower().endswith('.jar') or name.lower().endswith('.war') or name.lower().endswith('.ear')):
                # skip non-jars
                continue
            jarpath = os.path.join(root, name)
            do_jarfile_from_disk(jarpath)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Scanner for jars that may be vulnerable to CVE-2021-44228')
    parser.add_argument('dir', nargs='?', help='Top-level directory to start looking for jars', default='.')
    args = vars(parser.parse_args())
    main(args['dir'])
