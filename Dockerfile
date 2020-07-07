FROM registry.svc.ci.openshift.org/openshift/release:golang-1.13 AS builder
WORKDIR /go/src/github.com/openshift/cluster-version-operator
COPY . .
RUN hack/build-go.sh; \
    mkdir -p /tmp/build; \
    cp _output/linux/$(go env GOARCH)/cluster-version-operator /tmp/build/cluster-version-operator

FROM registry.svc.ci.openshift.org/openshift/origin-v4.0:base AS tmp
COPY --from=builder /tmp/build/cluster-version-operator /usr/bin/
COPY install /manifests
COPY vendor/github.com/openshift/api/config/v1/0000_00_cluster-version-operator_01_clusterversion.crd.yaml /manifests/
COPY vendor/github.com/openshift/api/config/v1/0000_00_cluster-version-operator_01_clusteroperator.crd.yaml /manifests/
COPY bootstrap /bootstrap
ENTRYPOINT ["/usr/bin/cluster-version-operator"]

FROM quay.io/openshift-release-dev/ocp-release@sha256:38097188e619880aefac3c7a621d8a5c4d3c6aa0d7836e325470f3e3ebdebd4f
COPY --from=tmp /usr/bin/cluster-version-operator /usr/bin/cluster-version-operator
COPY 0000_50_cluster-ingress-operator_02-deployment.yaml /release-manifests/
COPY 0000_50_cluster-ingress-operator_02-deploymentcrc.yaml /release-manifests/
RUN rm /release-manifests/0000_90_cluster-update-keys_configmap.yaml
