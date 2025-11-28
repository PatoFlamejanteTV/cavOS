#!/usr/bin/env bash
set -x # show cmds
set -e # fail globally

if [ "$#" -ne 3 ]; then
	echo "Usage: $0 <automake-version> <autoconf-version> <install-prefix>"
	exit 1
fi

automake_version=$1
autoconf_version=$2
install_prefix=$3

mkdir -p "$install_prefix"

mkdir -p tmp_get_autotools
cd tmp_get_autotools

build_package() {
    package_name=$1
    version=$2
    install_dir=$3

    file="$package_name-$version.tar.gz"
    url="https://ftp.gnu.org/gnu/$package_name/$file"

    echo "-> Downloading $file from $url"

    # Try normal download
    if ! wget -nc "$url"; then
        echo "X Failed to download from official server."
        echo "-> Trying to find it on the Wayback Machine…"

        # Query Wayback Machine API to find latest snapshot
        wayback_info=$(curl -s "https://archive.org/wayback/available?url=$url")
        wayback_url=$(printf "%s" "$wayback_info" | grep -oP '"url":"\K[^"]+')

        if [ -n "$wayback_url" ]; then
            echo "-> Snapshot found: $wayback_url"
            if ! wget -nc "$wayback_url" -O "$file"; then
                echo "X Failed to download even via Wayback."
                return 1
            fi
        else
            echo "X No snapshot found on the Wayback Machine."
            return 1
        fi
    fi

    # Extraction and build
    tar -xf "$file"
    cd "$package_name-$version"
    ./configure --prefix="$install_dir"
    make
    make install
    cd ..
}


build_package "automake" "$automake_version" "$install_prefix"
build_package "autoconf" "$autoconf_version" "$install_prefix"

cd ..
rm -rf tmp_get_autotools
