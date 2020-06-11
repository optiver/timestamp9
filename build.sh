set -e

mkdir build
cd build

supported_versions=( 11 12 )
for version in "${supported_versions[@]}"
do
    rm -rf *
    cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo -DPG_CONFIG=/usr/pgsql-${version}/bin/pg_config
    make -j4
    cpack
    cp *rpm ../
done

cp ../*rpm /mnt/releases/postgresql

