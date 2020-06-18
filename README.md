# Vault Splunk Stack (VSS)

## What?

It is a small Docker based stack composed by Terraform, and consisting of:

1. Splunk
2. Telegraf
3. Vault

## Why?

To quickly spin up an environment for using Vault telemetry metrics with Splunk

## How?

1. Install [Docker](https://www.docker.com/products/docker-desktop) for your OS
1. Install [Terraform](https://www.terraform.io/downloads.html) for your OS
1. Clone this repository
1. Change into the directory and use `terraform` to start the show!

```shell
$ cd vss && \
terraform init && \
terraform plan -out vss.plan && \
terraform apply -auto-approve vss.plan
```

**Okay, now what?**

Vault is configured and running as a single server with a filesystem based storage backend, no TLS enabled, and telemetry configured to use Telegraf.

Telegraf is spun up with a configuration that uses a HEC to connect to Splunk and push metrics.

Splunk is spun up with a fully configured **vault-metrics** index and HEC for receiving metrics forwarded by Telegraf.

It's all ready to use out-of-the-box.

## Use Vault

Export VAULT_ADDR to communicate with the Vault container.

```shell
$ export VAULT_ADDR=http://127.0.0.1:8200
```

Get a quick status.

```shell
$ vault status
Key                Value
---                -----
Seal Type          shamir
Initialized        false
Sealed             true
Total Shares       0
Threshold          0
Unseal Progress    0/0
Unseal Nonce       n/a
Version            n/a
HA Enabled         false
```

## Use Splunk

## Cleanup

When finished, you can reset like this.

```shell
$ terraform destroy --force
```
