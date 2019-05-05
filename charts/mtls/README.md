# MTLS Helm Chart

This directory contains a Kubernetes chart to deploy a [MTLS Server][mtls-server].

## Prerequisites Details

* Kubernetes 1.11+

## Chart Details

This chart will do the following:

* Implement a MTLS Deployment

This system itself will not use Client Certificate Authentication as it uses a
detached signed PGP message to check for authentication when generating
certificates from a CSR.

## Installing the Chart

To install the chart, use the following:

### With Password

NOTE: CA Name Normalized is the CA name without punctuation or spaces.
ex. My Company, Inc. -> MyCompanyInc

To be able to add intermediate certificates later and keeping the serial numbers in order, it is recommended that you keep a copy of the final output folder for reuse later. This can be done by taring or ziping the folder and encrypting it to keep these items secure. If you lose your Root CA Key/Certificate, you will need to regenrate everything.

```shell
$ helm repo add incuabor https://storage.googleapis.com/kubernetes-charts-incubator
# If you do not already have a CA or Intermediate Certificate run the following
# commands to generate the Root CA and Key which will be used as secrets when
installing.
$ WITHPASSWORD=true ./scripts/create-ca.sh
# If not using an intermediate certificate as recommended
$ echo "<Root Key Password>" > output/ca/private/key.password
# If using an intermediate certificate as recommended
$ ./scripts/create-intermediate.sh
$ echo "<Intermediate Key Password>" > output/ca/intermediate/<CA Name Normalized>/private/key.password
$ helm install \
  --namespace kube-system \
  -f values.yaml \
  --set env.FQDN=<my.fqdn.net> \
  --set secrets.enabled=true \
  --set secrets.intermediateDomain=<intermediateDomain> \
  .
```

### Without Password

```shell
$ helm repo add incuabor https://storage.googleapis.com/kubernetes-charts-incubator
# If you do not already have a CA or Intermediate Certificate run the following
# commands to generate the Root CA and Key which will be used as secrets when
installing. This will give you the option to create an intermediate certificate. You can either choose to do that now or later. If you decide to do this later, you still have that option by running `./scripts/create-intermediate.sh`
$ ./scripts/create-ca.sh
$ helm install \
  --namespace kube-system \
  -f values.yaml \
  --set env.FQDN=<my.fqdn.net> \
  --set secrets.enabled=true \
  --set secrets.intermediateDomain=<intermediateDomain> \
  .
```

## Securing your other Ingresses

To add client certificate authentication to your resource you will need to add
a few annotations to your ingress. These annotations will add the appropriate
secrets and enable client certificate authentication.

On a service that should integrate with mtls you will need to add the following
annotations to your ingress:

```
ingress:
  annotations:
    kubernetes.io/ingress.class: nginx
    # Enable client certificate authentication
    nginx.ingress.kubernetes.io/auth-tls-verify-client: "on"
    # Create the secret containing the trusted ca certificates
    nginx.ingress.kubernetes.io/auth-tls-secret: "<NAMESPACE>/<FULLNAME>-certs"
    # Specify the verification depth in the client certificates chain
    nginx.ingress.kubernetes.io/auth-tls-verify-depth: "1"
    # Specify if certificates are passed to upstream server
    nginx.ingress.kubernetes.io/auth-tls-pass-certificate-to-upstream: "false"
```

## Configuration

The following table lists the configurable parameters of the MTLS Chart and
their defaults.

| Parameter                         | Description                                                                             | Default                        |
| ---------                         | -----------                                                                             | -------                        |
| `env.FQDN`                        | The FQDN of the service                                                                 | `chart-example.local`          |
| `env.PROTOCOL`                    | The protocol the end service uses.                                                      | `https`                        |
| `env.CONFIG_PATH`                 | The configuration file path                                                             |                                |
| `env.*`                           | Replace * with the Env Var name and it will be injected into the containers environment |                                |
| `secrets.enabled`                 | Enable secrets                                                                          | `false`                        |
| `secrets.intermediateDomain`      | The intermediate domain folder for pulling the secrets                                  | `false`                        |
| `secrets.hasPassword`             | The intermediate certificate has a password. This will be pulled from a file            | `false`                        |
| `image.repository`                | `mtls` image repository                                                                 | `drgrove/mtls`                 |
| `image.tag`                       | `mtls` image tag.                                                                       | `v0.12.0`                      |
| `image.pullPolicy`                | Image pull policy                                                                       | `IfNotPresent`                 |
| `config`                          | Base configuration for `mtls`                                                           | [see values.yaml](values.yaml) |
| `admin_seeds`                     | ASCII Armored PGP Keys for Seeding Admin Trust Database                                 | `{}`                           |
| `user_seeds`                      | ASCII Armored PGP Keys for Seeding User Trust Database                                  | `{}`                           |
| `service.enabled` | Enable the service | `true` |
| `service.type` | The type of the service | `ClusterIP` |
| `service.port` | The port of the service | `4000` |
| `ingress.enabled` | Enable the ingress | `false` |
| `ingress.annotations` | Annotations for the ingress | `{}` |
| `ingress.paths` | Paths for the ingress | `['/']` |
| `ingress.hosts` | Hosts for ingress | `['chart-example.local']`
| `persistence.sqlite3.enabled`     | Create a volume to store data for sqlite3                                               | `true`                         |
| `persistence.user_gnupg.enabled`  | Create a volume to store data for user gnupg keys                                       | `true`                         |
| `persistence.admin_gnupg.enabled` | Create a volume to store data for admin gnupg keys                                      | `true`                         |
| `persistence.size`                | Size of persistent volume claim                                                         | 10Gi RW                        |
| `persistence.storageClass`        | Type of persistent volume claim                                                         | `nil`                          |
| `persistence.accessMode`          | ReadWriteOnce or ReadOnly                                                               | `ReadWriteOnce`                |
| `persistence.existingClaim`       | Name of existing persistent volume                                                      | `nil`                          |
| `persistence.subPath`             | Subdirectory of the volume to mount                                                     | `nil`                          |
| `persistence.annotations`         | Persistent Volume annotations                                                           | `{}`                           |
| `nodeSelector`                    | Node labels for pod assignment                                                          | `{}`                           |
| `tolerations`                     | Pod taint tolerations for deployment                                                    | `{}`                           |
service:
  enabled: true
  type: ClusterIP
  port: 4000

ingress:
  enabled: false
  annotations: {}
    # kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"
  paths:
    - /
  hosts:
    - *fqdn
  tls: []

[mtls-server]: https://github.com/drGrove/mtls-server
