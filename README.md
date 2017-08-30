# pybld
Build different versions of python locally with virtual environments.

This tool downloads, builds and installs a particular version of python in the location of your choice without requiring root permissions. It also creates a virtual environment that you can activate to use it.

It is very useful for staging tests.

I have tested it on CentOS 6.6 linux and Mac OS X 10.10.3.

### Example
Here is an example that shows how to install 2.7.10 and 3.4.3 in a local directory tree.

```bash
$ # Create the top level work directory.
$ mkdir ~/work/python

$ # Downlod pybld.sh, make sure that it is executable.
$ curl -k -L -O http://projects.joelinoff.com/pybld/pybld.sh
$ sum pybld.sh
08374    12
$ chmod a+x pybld.sh

$ # Build Python 2.7.10 and test.
$ ./pybld.sh -v 2.7.10 -b 2.7.10/bld -r 2.7.10
[output_snipped]
$ # test it
$ source 2.7.10/venv/python2710/bin/activate
(python2710)$ python --version
Python 2.7.10
(python2710)$ pip2 freeze  # installed packages for this release
[output snipped]
(python2710)$ deactivate

$ # Build Python 3.4.3 and test.
$ ./pybld.sh -v 3.4.3 -b 3.4.3/bld -r 3.4.3
[output snipped]
$ # test it
$ source 3.4.3/venv/python343/bin/activate
(python343) python --version
Python 3.4.3
(python343) pip3 freeze  # installed packages for this release
[output snipped]
(python343) deactivate
```

### Delete
To delete the installed versions of python simply build, release and venv directories.

```bash
$ # delete my locally built version of 2.7.9
$ rm -rf ~/work/python/2.7.3
```

### Customize the configuration
If you need to customize the Python build, simply edit the script and change the configure command around line 316.

You can search for the line that contains "*runcmd ./configure --prefix*".
