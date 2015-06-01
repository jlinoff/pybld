#!/bin/bash
#
# Install a specified version of python locally without root
# privilege. See the help for more information.
#

# LICENSE (MIT)
# Copyright (c) 2015 Joe Linoff
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# ================================================================
# Functions
# ================================================================
function runcmd() {
    local Cmd=''
    for Arg in "$@" ; do
        if echo "$Arg" | grep ' ' 1>/dev/null ; then
            Cmd="$Cmd '$Arg'"
        else
            Cmd="$Cmd $Arg"
        fi
    done
    Cmd=${Cmd:1}

    echo "INFO: Cmd: $Cmd"
    eval time $Cmd

    local Status=$?
    echo "INFO: Status: $Status"
    if (( $Status )) ; then
        exit $Status
    fi
    return 0
}

# Get the abspath of an existing file/dir.
# Mac OS X doesn't support readlink.
# This doesn't work exactly like readlink -f because it requires the
# path to exist but that is okay for this use.
function abspath() {
    local RelPath="$1"
    local UsePushd=0
    if which readlink >/dev/null 2>&1 ; then
        # Platform has readlink.
        readlink -f "$RelPath" 2>/dev/null
        local Status=$?
        if (( $Status )) ; then
            # readlink -f failed: probably Mac OS X.
            UsePushd=1
        fi
    else
        # Platforms that don't have readlink.
        UsePushd=1
    fi

    if (( $UsePushd )) ; then
        # Platforms that don't have readlink -f.
        if [ -d "$RelPath" ] ; then
            pushd "$RelPath" 1>/dev/null
            pwd
            popd 1>/dev/null
        else
            local RelDirPath=$(dirname -- "$RelPath")
            pushd "$RelDirPath" 1>/dev/null
            echo "$(pwd)/$(basename $RelPath)"
            popd 1>/dev/null
        fi
    fi
    return 0
}

# Make a path if it doesn't already exist.
function mkpath() {
    local MkPath="$1"
    if [ ! -d "$MkPath" ] ; then
        mkdir -p "$MkPath" >/dev/null 2>&1
        local Status=$?
        if (( $Status )) ; then
            echo "ERROR: Unable to create directory path: $MkPath"
            exit 1
        fi
    fi
    echo "$MkPath"
    return 0
}

function help() {
cat <<EOF
USAGE
        $0 [OPTIONS]

DESCRIPTION
        This tool downloads, builds and installs a particular version
        of python in the location of your choice without requiring
        root permissions.

        It also creates a virtual environment that you can activate
        to use it.

        Here is an example usage:

           \$ mkdir -p ~/work/python/2.7.10
           \$ cd ~/work/python/2.7.10
           \$ $0 -v 2.7.10
           \$ ls -1 build rtf rtf/venv  # where stuff is built and released

           \$ mkdir -p ~/work/python/3.4.1
           \$ cd ~/work/python/3.4.1
           \$ $0 -v 3.4.1
           \$ ls -1 build rtf rtf/venv

        In both cases, the specified version of python will be
        downloaded and built in the local build directory. It will
        be released to the local rtf directory and the virtualenv
        (pyvenv) directory will in rtf/venv.

        You can can customize the build, release and venv directories
        as seen in this example:

           \$ # Download and build in ~/work/python/2.7.10.
           \$ # Release to /opt/python/2.7.10.
           \$ # Create a virtual environment in /opt/python/2.7.10/venv.
           \$ $0 -v 2.7.10 -r /opt/python/2.7.10 -b ~/work/python/2.7.10

        Once you have built and installed python, you can use it by
        activating the virtual environment or you could add it your
        local module configuration.

           \$ /opt/python/2.7.10/venv/python2710/bin/activate
           
        To remove the installation, simply remove the bld, release and
        venv directories.

OPTIONS
        -b <dir>, --build-dir <dir>
                        The build directory. It can be deleted after
                        successfully installing python.
                        Default: $BuildDir

        -h, --help      This help message.

        -r <dir>, --release-dir <dir>
                        The release directory (contains bin/python).
                        Default: $ReleaseDir

        -t, --test      Enable testing. This can really slow down
                        the build process.

        -e <dir>, --venv-dir <dir>
                        The virtualenv directory (contains bin/activate).
                        Default: $DefVenvDir

        -v, --version   The version of python to install.
                        Default: $VersionDir

EXAMPLES
        \$ # Get help.
        \$ $0 -h

        \$ # Build and install in the current directory.
        \$ $0 -v $Version 2>&1 | tee log

        \$ # Build and release in specific directories.
        \$ $0 -v $Version \\
                -r /opt/python/$Version \\
                -e /opt/python/$Version/venv \\
                -b /opt/build/python/$Version \\
                2>&1 | tee log

        \$ # Use the new version built in the previous example.
        \$ source /opt/python/$Version/venv/$DefVenvDirName/bin/activate
        ($DefVenvDirName)\$ python --version
        Python $Version
        ($DefVenvDirName)\$ pip freeze   # python 2.x see which packages are installed
        ($DefVenvDirName)\$ pip3 freeze  # python 3.x see which packages are installed
        ($DefVenvDirName)\$ deactivate   # leave this python version

        \$ # Remove the specific directories example installation.
        \$ rm -rf /opt/python/$Version /opt/build/python/$Version

VERSION
        1.0
EOF
}

# ================================================================
# Main
# ================================================================
MeDir=$(dirname -- $(abspath $0))
BldDir="$MeDir/build"
RtfDir="$MeDir/rtf"
Version="2.7.10"
DefVenvDirName=$(echo "python$Version" | tr -d '.-')
DefVenvDir="$RtfDir/venv/$DefVenvDirName"
VenvDir=''
Test=0

while (( $# )) ; do
    opt="$1"
    shift
    case "$opt" in
        -h|--help)
            help
            exit 0
            ;;
        -b|--build-dir)
            BldDir="$1"
            shift
            if [[ "$BldDir" == "" ]] ; then
                echo "ERROR: Empty build directory not allowed."
                exit 1
            fi
            ;;
        -r|--release-dir)
            RtfDir="$1"
            shift
            if [[ "$RtfDir" == "" ]] ; then
                echo "ERROR: Empty release directory not allowed."
                exit 1
            fi
            DefVenvDirName=$(echo "python$Version" | tr -d '.-')
            DefVenvDir="$RtfDir/venv/$DefVenvDirName"
            ;;
        -t|--test)
            Test=1
            ;;
        -e|--venv-dir)
            VenvDir="$1"
            shift
            if [[ "$VenvDir" == "" ]] ; then
                echo "ERROR: Empty virtualenv directory not allowed."
                exit 1
            fi
            ;;
        -v|--version)
            Version="$1"
            shift
            Regex='[0-9]+\.[0-9]+\.[0-9]+$'
            if [[ ! "$Version" =~ $Regex ]] ; then
                echo "ERROR: Invalid version specification: $Version."
                echo "       Expected something like 2.7.10."
                exit 1
            fi
            DefVenvDirName=$(echo "python$Version" | tr -d '.-')
            DefVenvDir="$RtfDir/venv/$DefVenvDirName"
            ;;
    esac
done

if [[ "$VenvDir" == "" ]] ; then
    VenvDir="$DefVenvDir"
fi

Root="Python-$Version"
Archive="$Root.tgz"

# Abspath.
BldDir=$(abspath $(mkpath "$BldDir"))
RtfDir=$(abspath $(mkpath "$RtfDir"))
VenvDir=$(abspath $(mkpath "$VenvDir"))

echo "INFO: ================================================================"
echo "INFO: Host    $(hostname)"
echo "INFO: Date    $(date)"
echo "INFO: Who     $(whoami)"
echo "INFO: Python  $Version"
echo "INFO: BldDir  $BldDir"
echo "INFO: RtfDir  $RtfDir"
echo "INFO: VenvDir $VenvDir"
echo "INFO: ================================================================"

# Cd to the build directory.
cd $BldDir

if [ ! -f $Archive ] ; then
    echo "INFO: Downloading python archive: $Archive."
    runcmd wget https://www.python.org/ftp/python/$Version/$Archive -O $Archive
else
    echo "INFO: Downloaded python archive: $Archive."
fi

# Extract
if [ ! -d $Root ] ; then
    echo "INFO: Extracting $Archive"
    runcmd tar zxf $Archive
else
    echo "INFO: Extracted $Archive"
fi

# Configure and build.
if [ ! -e $RtfDir/bin/python ] ; then
    echo "INFO: Building python"
    if [ ! -d $Root ] ; then
        echo "ERROR: Directory does not exist: $Root."
        exit 1
    fi
    cd $Root
    runcmd ./configure --help 2>&1| tee configure.help
    runcmd ./configure --prefix=$RtfDir
    runcmd make
    if (( $Test )) ; then
        # I don't do this by default because i have
        # seen false positives.
        runcmd make test
    fi
    runcmd make install
else
    echo "INFO: Built python."
fi

# Install pip.
if [ ! -f $RtfDir/bin/pip2 ] && [ -f $RtfDir/bin/python2 ] ; then
    echo "INFO: Installing pip for Python 2.x."
    runcmd $RtfDir/bin/python -m ensurepip --upgrade
    runcmd $RtfDir/bin/pip install --upgrade pip
fi

# Install the virtual environment.
if [ -f $RtfDir/bin/pip3 ] ; then
    # Python 3.x - use pip3 and pyvenv.
    RequiredFiles=($RtfDir/bin/pip3 $RtfDir/bin/pyvenv)
    for RequiredFile in ${RequiredFiles[@]} ; do
        if [ ! -f $RequiredFile ] ; then
            BaseName=$(basename $RequiredFile)
            echo "ERROR: Unexpected condition: $BaseName not found."
            exit 1
        fi
    done

    # Create a virtual environment.
    if [ ! -f $VenvDir/bin/activate ] ; then
        echo "INFO: Creating $VenvDir."
        runcmd $RtfDir/bin/pyvenv $VenvDir
    else
        echo "INFO: Created $VenvDir."
    fi

elif [ -f $RtfDir/bin/pip2 ] ; then
    # Python 2.x - use virtualenv and pip2
    if [ ! -f $RtfDir/bin/virtualenv ] ; then
        echo "INFO: Installing virtualenv."
        runcmd $RtfDir/bin/pip2 install virtualenv
    else
        echo "INFO: Installed virtualenv."
    fi

    # Create a virtual environment.
    if [ ! -f $VenvDir/bin/activate ] ; then
        echo "INFO: Creating $VenvDir."
        runcmd $RtfDir/bin/virtualenv $VenvDir
    else
        echo "INFO: Created $VenvDir."
    fi

fi
