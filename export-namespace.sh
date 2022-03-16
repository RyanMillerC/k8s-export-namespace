#!/bin/bash
#
# Export all non-generated objects from a Kubernetes namespace. This script was
# only tested on RHEL 8. This script will have issues running on MacOS.
#
# USAGE: ./export-namespace.sh NAMESPACE
#
# This script requires the following kubectl plugins installed either manually
# or with 'krew' (https://krew.sigs.k8s.io/docs/user-guide/setup/install):
#
# - `$ kubectl krew install get-all`
# - `$ kubectl krew install neat`
# - `$ kubectl krew install slice`
#
# To use a different Kuberentes CLI (OpenShift), set 'K8S_EXECUTABLE' with:
# `$ export K8S_EXECUTABLE='oc'`
#

set -e

# Default to 'kubectl' but allow custom Kuberentes CLI
if [[ -z ${K8S_EXECUTABLE} ]] ; then
    K8S_EXECUTABLE='kubectl'
fi

# Don't change these...
NAMESPACE="${1}"
WORK_DIR="$(mktemp -d)"

# Pre-flight checks
if [[ -z ${NAMESPACE} ]] ; then
    >&2 echo 'USAGE: ./export-namespace.sh NAMESPACE'
    exit 1
elif [[ -d ${NAMESPACE} ]] ; then
    >&2 echo "./${NAMESPACE} already exists!"
    exit 1
elif ! command -v ${K8S_EXECUTABLE} &> /dev/null ; then
    >&2 echo "'${K8S_EXECUTABLE}' not found."
    >&2 echo "If you need to use 'oc' instead of 'kubectl' set 'export K8S_EXECUTABLE=oc'"
    exit 1
elif ! command -v kubectl-get_all &> /dev/null ; then
    >&2 echo "'${K8S_EXECUTABLE} get-all' not found. Install manually or with krew:"
    >&2 echo "'${K8S_EXECUTABLE} krew install get_all"
    exit 1
elif ! command -v kubectl-neat &> /dev/null ; then
    >&2 echo "'${K8S_EXECUTABLE} neat' not found. Install manually or with krew:"
    >&2 echo "'${K8S_EXECUTABLE} krew install neat'"
    exit 1
elif ! command -v kubectl-slice &> /dev/null ; then
    >&2 echo "'${K8S_EXECUTABLE} slice' not found. Install manually or with krew:"
    >&2 echo "'${K8S_EXECUTABLE} krew install slice"
    exit 1
fi

echo "Using ${WORK_DIR} as working directory." \
     "Check this directory if something goes wrong."
cd ${WORK_DIR}

echo "Exporting all objects from namespace '${NAMESPACE}'..."
${K8S_EXECUTABLE} get-all \
    --exclude builds,events,imagetags,imagestreamtags,packagemanifests \
    -n "${NAMESPACE}" \
    -o yaml \
    > "${WORK_DIR}/export.yaml"

echo 'Splitting exported object into individual files...'
${K8S_EXECUTABLE} slice \
    -f "${WORK_DIR}/export.yaml" \
    -o "${WORK_DIR}"

rm -f "${WORK_DIR}/export.yaml"

echo 'Removing cluster specific references from objects...'
mkdir "${WORK_DIR}/neat"
for FILE in *.yaml ; do
    ${K8S_EXECUTABLE} neat \
        -f "${WORK_DIR}/${FILE}" \
        > "${WORK_DIR}/neat/${FILE}"
done

echo "Copying processed YAML files to ./${NAMESPACE}..."
cd - # Return to original directory
mv "${WORK_DIR}/neat" "./${NAMESPACE}"

echo "Cleaning up tmp files..."
rm -rf "${WORK_DIR}"

echo 'Done!'
