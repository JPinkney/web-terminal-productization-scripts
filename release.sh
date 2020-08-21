
FILENAME="brew-nvrs-release-"`date +"%Y-%m-%d"`".txt"
touch $FILENAME

USAGE="Usage: ./release.sh [OPTIONS]
Options:
    --help
        Print this message.
    --exec, -e
        Rebuild exec container
    --tooling, -t
        Rebuild tooling container
    --operator, -o
        Rebuild operator container
    --metadata, -m
        Rebuild metadata container
    -p
        Push resulting images to quay WTO organization
"

function print_usage() {
    echo -e "$USAGE"
}

BUILD_EXEC=false
BUILD_TOOLING=false
BUILD_OPERATOR=false
BUILD_METADATA=false
PUSH_TO_QUAY=false

function parse_arguments() {
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            -e|--exec)
            BUILD_EXEC=true
            shift 1
            ;;
            -t|--tooling)
            BUILD_TOOLING=true
            shift 1
            ;;
            -o|--operator)
            BUILD_OPERATOR=true
            shift 1
            ;;
            -m|--metadata)
            BUILD_METADATA=true
            shift 1
            ;;
            -p)
            PUSH_TO_QUAY=true
            shift 1
            ;;
            '--help')
            print_usage
            exit 0
            ;;
            *)
            echo -e "Unknown option $1 is specified. See usage:\n"
            print_usage
            exit 0
        esac
    done
}

function release () {
    echo "Starting $1 release process"
    cd $1
    rhpkg --verbose container-build --target=web-terminal-1.0-rhel-8-containers-candidate > tmp.log 2>&1
    NVR=$(cat tmp.log | grep -A1 "nvrs:" | tail -n 1)
    rm tmp.log
    echo "Finished $1 release process. Brew NVR is: $NVR"
    echo $NVR >> $FILENAME
    cd ..
}

parse_arguments "$@"

function push_to_quay () {
    REGISTRY=registry-proxy.engineering.redhat.com/rh-osbs
    BREW_IMG=$REGISTRY/$1
    docker pull $BREW_IMG
    docker tag $BREW_IMG quay.io/wto/$1
    docker push quay.io/wto/$1
}

if [ "$BUILD_EXEC" = true ];
then
    release "web-terminal-exec"
    if [ "$PUSH_TO_QUAY" = true ];
    then
        push_to_quay "web-terminal-exec:latest"
    fi
fi

if [ "$BUILD_TOOLING" = true ];
then
    release "web-terminal-tooling"
    if [ "$PUSH_TO_QUAY" = true ];
    then
        push_to_quay "web-terminal-tooling:latest"
    fi
fi

if [ "$BUILD_OPERATOR" = true ];
then
    release "web-terminal"
    if [ "$PUSH_TO_QUAY" = true ];
    then
        push_to_quay "web-terminal-operator:latest"
    fi
fi

if [ "$BUILD_METADATA" = true ];
then
    release "web-terminal-dev-operator-metadata"
    if [ "$PUSH_TO_QUAY" = true ];
    then
        push_to_quay "web-terminal-operator-metadata:latest"
    fi
fi





