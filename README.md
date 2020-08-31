# web-terminal-productization-scripts

### ./release\.sh - Automatically build images in brew
```
Usage: ./release.sh [OPTIONS]
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
```

### ./sync\.sh - Sync an upstream repo with a downstream one
```
Variables:
SOURCE_BRANCH
GITHUB_TOKEN
DWNSTM_REPO
DWNSTM_BRANCH
Usage: ./sync.sh
```

### ./test-index\.sh - Given an index from brew automatically apply image mapping
```
Usage:   ./test-index.sh -i [ORIGINAL_INDEX] -t [TARGET_INDEX]
Options:
  --index,  -i     the index which should be tested
                   To find index see Index Image Location in cvp-test-report of
                   web-terminal-operator-metadata-container-
                   http://external-ci-coldstorage.datahub.redhat.com/cvp/cvp-redhat-operator-bundle-image-validation-test/

  --target, -t     the target where mirrored index should be pushed

  --verbose, -v    print the verbose output during execution

  --help,   -h     help
```
