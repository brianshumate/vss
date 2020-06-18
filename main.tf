# =======================================================================
# Vault Splunk Stack - quick 'n easy Vault + Telegraf + Splunk
#
# You take some Vault and some Splunk...
# =======================================================================

terraform {
  required_version = ">= 0.12"
}

# -----------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------

variable "splunk_version" {
  default = "8.0.4.1"
}

variable "telegraf_version" {
  default = "1.12.6"
}

variable "vault_version" {
  default = "1.4.2"
}

variable "splunk_ip" {
  default = "42c0ff33-c00l-7374-87bd-690ac97efc50"
}

# -----------------------------------------------------------------------
# Global config
# -----------------------------------------------------------------------

terraform {
  backend "local" {
    path = "tfstate/terraform.tfstate"
  }
}

# "This is fine"
provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# -----------------------------------------------------------------------
# Splunk
# -----------------------------------------------------------------------

resource "docker_image" "splunk" {
  name         = "splunk/splunk:${var.splunk_version}"
  keep_locally = true
}

resource "docker_container" "splunk" {
  name  = "vss-splunk"
  image = docker_image.splunk.latest
  env   = ["SPLUNK_START_ARGS=--accept-license", "SPLUNK_ETC=/opt/splunk/etc", "SPLUNK_PASSWORD=vss-password"]
  volumes {
    host_path      = "${path.cwd}/config/default.yml"
    container_path = "/tmp/defaults/default.yml"
  }
  ports {
    internal = "8000"
    external = "8000"
    protocol = "tcp"
  }

}

# output "splunk_ip" {
#   value = docker_container.splunk.ip_address
# }

# -----------------------------------------------------------------------
# Telegraf
# -----------------------------------------------------------------------

data "template_file" "telegraf_configuration" {
  template = file(
    "${path.cwd}/config/telegraf.conf",
  )
  vars = {
    splunk_address = "${docker_container.splunk.ip_address}"
  }
}

resource "docker_image" "telegraf" {
  name         = "telegraf:${var.telegraf_version}"
  keep_locally = true
}

resource "docker_container" "telegraf" {
  name  = "vss-telegraf"
  image = docker_image.telegraf.latest
  upload {
    content = data.template_file.telegraf_configuration.rendered
    file    = "/etc/telegraf/telegraf.conf"
  }
}

# output "telegraf_ip" {
#   value = docker_container.telegraf.ip_address
# }

# -----------------------------------------------------------------------
# Vault
# -----------------------------------------------------------------------

data "template_file" "vault_configuration" {
  template = file(
    "${path.cwd}/config/vault.hcl",
  )
  vars = {
    telegraf_address = "${docker_container.telegraf.ip_address}"
  }
}

resource "docker_image" "vault" {
  name         = "vault:${var.vault_version}"
  keep_locally = true
}

resource "docker_container" "vault" {
  name     = "vss-vault"
  image    = docker_image.vault.latest
  env      = ["SKIP_CHOWN", "VAULT_ADDR=http://127.0.0.1:8200"]
  command  = ["vault", "server", "-log-level=trace", "-config=/vault/config"]
  hostname = "vss-vault"
  must_run = true
  capabilities {
    add = ["IPC_LOCK"]
  }
  healthcheck {
    test         = ["CMD", "vault", "status"]
    interval     = "10s"
    timeout      = "2s"
    start_period = "10s"
    retries      = 2
  }
  ports {
    internal = "8200"
    external = "8200"
    protocol = "tcp"
  }
  upload {
    content = data.template_file.vault_configuration.rendered
    file    = "/vault/config/server.hcl"
  }
}
