echo running
rm -rf /tmp/t2-build-result
mkdir -p /tmp/t2-build-result
rm -rf /tmp/t2-build
mkdir -p /tmp/t2-build
cd /tmp/t2-build
tar xf /tmp/t2-build-input.tar.gz

pre-gypify --package_name "{name}-v{version}-{node_abi}-{platform}-{arch}-{configuration}.tar.gz"

export STAGING_DIR=/mnt/sda1/toolchain/
export PANGYP_RUNTIME=iojs
export NODEGYP=pangyp
export NODE=1.2.0
#export TOOLCHAIN_ARCH=mips
#export ARCH=mipsel

echo OHOHOH
echo $TOOLCHAIN_ARCH
echo $NODE

set -e

if [ ! -d "$STAGING_DIR" ]; then
    echo "STAGING_DIR needs to be set to your cross toolchain path";
    exit 1
fi

ARCH=${ARCH:-mipsel}
NODE=${NODE:-0.10.33}
NODEGYP=${NODEGYP:-node-gyp}

TOOLCHAIN_DIR=$(ls -d "$STAGING_DIR/toolchain-"*"$TOOLCHAIN_ARCH"*)
echo $TOOLCHAIN_DIR

export SYSROOT=$(ls -d "$STAGING_DIR/target-"*"$TOOLCHAIN_ARCH"*)

source $TOOLCHAIN_DIR/info.mk # almost a bash script

echo "Cross-compiling for" $TARGET_CROSS

export PATH=$TOOLCHAIN_DIR/bin:$PATH
export CPPPATH=$TARGET_DIR/usr/include
export LIBPATH=$TARGET_DIR/usr/lib

#TODO: anything better than this hack?
OPTS="-I $SYSROOT/usr/include -L $TOOLCHAIN_DIR/lib -L $SYSROOT/usr/lib"

export CC="${TARGET_CROSS}gcc $OPTS"
export CXX="${TARGET_CROSS}g++ $OPTS"
export AR=${TARGET_CROSS}ar
export RANLIB=${TARGET_CROSS}ranlib
export LINK="${TARGET_CROSS}g++ $OPTS"
export CPP="${TARGET_CROSS}gcc $OPTS -E"
export STRIP=${TARGET_CROSS}strip
export OBJCOPY=${TARGET_CROSS}objcopy
export LD="${TARGET_CROSS}g++ $OPTS"
export OBJDUMP=${TARGET_CROSS}objdump
export NM=${TARGET_CROSS}nm
export AS=${TARGET_CROSS}as

export npm_config_arch=$ARCH
export npm_config_node_gyp=$(which $NODEGYP)
npm install --ignore-scripts
node-pre-gyp rebuild --target=$NODE --debug
node-pre-gyp package --target_platform=openwrt --target_arch=$ARCH --target=$NODE --debug
node-pre-gyp rebuild --target=$NODE
node-pre-gyp package --target_platform=openwrt --target_arch=$ARCH --target=$NODE

find build/stage -type f | xargs -i cp {} /tmp/t2-build-result
cd /tmp/t2-build-result; tar czf ../t2-build.tar.gz .

# ./node_modules/.bin/node-pre-gyp unpublish --target_platform=openwrt --target_arch=$ARCH --target=$NODE --debug
# ./node_modules/.bin/node-pre-gyp publish --target_platform=openwrt --target_arch=$ARCH --target=$NODE --debug
