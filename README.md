# Vault Splunk Stack (VSS)

## What?

It is a small Docker based stack composed by Terraform, and consisting of:

1. Vault
1. Fluentd
1. Telegraf
1. Splunk

This project uses the [fluentd-splunk-hec](https://github.com/splunk/fluent-plugin-splunk-hec) image for the Fluentd component. It is not generally useful and mostly made for specific uses of this project. Check it out as an example of a custom Fluentd image with additional plugin installed.

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

Export the correct VAULT_ADDR value to communicate with the Vault container.

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

If everything is okay, go ahead and initialize, then unseal Vault, and login with the initial root token.

```shell
$ vault operator init \
      -key-shares=1 \
      -key-threshold=1 \
      | head -n3 \
      | cat > ./vault.init && \
      vault operator unseal \
      $(grep 'Unseal Key 1'  ./vault.init | awk '{print $NF}') && \
      vault login $(grep 'Initial Root Token' ./vault.init | awk '{print $NF}')
```

Enable a file audit device log.

```shell
$ vault audit enable file file_path=/vault/logs/vault-audit.log
```

Add a "sudo" policy.

```shell
$ vault policy write sudo - << EOT
// Example policy: "sudo"
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOT
```

Enable the userpass auth method.

```shell
$ vault auth enable userpass
```

Add a demo user and attach sudo policy.

```shell
$ vault write auth/userpass/users/demo password=abc.123 policies=sudo
```

Generate some stuff...

Login 200 times to generate some items in audit and metrics.

```shell
$ for i in {1..200}
    do
      vault login -method=userpass username=demo password=abc.123
    done
```

Create 142 identity entites.

```shell
$ for i in {1..142}
    do vault write -f identity/entity
  done
```

Create 200 tokens with only the default policy.

```shell
$ for i in {1..200}
    do vault token create -policy=default
  done
```

## Use Splunk

Visit [Splunk Web](http://127.0.0.1:8000) at 127.0.0.1:8000.

- Username: admin
- Password: vss-password

## Cleanup

When finished, you can reset like this.

```shell
$ terraform destroy --force
```
