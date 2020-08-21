INDEX_IMG=""
function parse_arguments() {
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            -i|--index)
            INDEX_IMG=$2
            shift 2
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

parse_arguments "$@"

rm -rf iib-manifests/

# Go through $INDEX_IMG and grab all the mappings
docker pull $INDEX_IMG
oc adm catalog mirror $INDEX_IMG quay.io/wto --manifests-only

cd iib-manifests

# Create the new mapped-images.txt that contains only the web-terminal mappings
grep web-terminal mapping.txt > mapped-images.txt

INDEX_LOCATION=quay.io/jpinkney/iib-v4.5:v4.5

# Add the actual index into the mapping
echo "$( docker inspect --format='{{index .RepoDigests 0}}' $INDEX_IMG )=$INDEX_LOCATION" >> mapped-images.txt

docker tag $INDEX_IMG $INDEX_LOCATION
docker push $INDEX_LOCATION

# Fix the right side of mapped-images.txt. Replace images with their proper upstream counterparts
sed -i 's/web-terminal-tech-preview-web-terminal-tooling-rhel8/web-terminal-tooling/g' mapped-images.txt
sed -i 's/web-terminal-tech-preview-web-terminal-exec-rhel8/web-terminal-exec/g' mapped-images.txt
sed -i 's/web-terminal-tech-preview-web-terminal-rhel8-operator/web-terminal-operator/g' mapped-images.txt
sed -i 's/rh-osbs-web-terminal-operator-metadata/web-terminal-operator-metadata/g' mapped-images.txt

# Fix the left side of mapped-images.txt. registry.redhat.io are not available until after the release happens so we defer to redhat proxy
sed -i 's/registry.redhat.io\/web-terminal-tech-preview\/web-terminal-rhel8-operator/registry-proxy.engineering.redhat.com\/rh-osbs\/web-terminal-operator/g' mapped-images.txt
sed -i 's/registry.redhat.io\/web-terminal-tech-preview\/web-terminal-exec-rhel8/registry-proxy.engineering.redhat.com\/rh-osbs\/web-terminal-exec/g' mapped-images.txt
sed -i 's/registry.redhat.io\/web-terminal-tech-preview\/web-terminal-tooling-rhel8/registry-proxy.engineering.redhat.com\/rh-osbs\/web-terminal-tooling/g' mapped-images.txt

rm -f mapping.txt

# Remove all unneed content source policies
yq -yi '. | del(.spec.repositoryDigestMirrors[] | select(.source | contains("web-terminal") | not ))' imageContentSourcePolicy.yaml

# Fix the imageContentSourcePolicy to point to the correct images on quay
sed -i 's/web-terminal-tech-preview-web-terminal-tooling-rhel8/web-terminal-tooling/g' imageContentSourcePolicy.yaml
sed -i 's/web-terminal-tech-preview-web-terminal-exec-rhel8/web-terminal-exec/g' imageContentSourcePolicy.yaml
sed -i 's/web-terminal-tech-preview-web-terminal-rhel8-operator/web-terminal-operator/g' imageContentSourcePolicy.yaml
sed -i 's/rh-osbs-web-terminal-operator-metadata/web-terminal-operator-metadata/g' imageContentSourcePolicy.yaml

oc image mirror --keep-manifest-list=true -f mapped-images.txt
oc apply -f imageContentSourcePolicy.yaml

echo "apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: web-terminal-crd-registry
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: $INDEX_LOCATION
  publisher: Red Hat
  displayName: Web Terminal Operator Catalog" | oc apply -f -
