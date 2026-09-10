set -e

mkdir build
cd build

supported_versions=( 14 15 16 17 )
for version in "${supported_versions[@]}"
do
    rm -rf *
    cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo -DPG_CONFIG=/usr/pgsql-${version}/bin/pg_config
    make -j4
    cpack
    cp *rpm ../
done

# Copy to release directory if specified, otherwise skip
RELEASE_DIR="${RELEASE_DIR:-/mnt/releases/postgresql}"
if [ -d "$RELEASE_DIR" ]; then
    cp ../*rpm "$RELEASE_DIR"
fi

