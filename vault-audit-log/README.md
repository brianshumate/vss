# vault-audit-log

This directory typically holds two files as a shared volume between the vss-vault and vss-fluentd containers:

- `vault-audit.log` is the actual Vault audit device log
- `vault-audit.log.pos` is the Fluent log position file
