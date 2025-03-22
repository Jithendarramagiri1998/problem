# Vault configuration file

# Storage backend configuration
storage "file" {
  path = "/vault/data"
}

# Listener configuration
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1  # Disable TLS for development purposes
}

# API address configuration
api_addr = "http://<vault-server-ip>:8200"

# Default lease duration for tokens and secrets
default_lease_ttl = "768h"
max_lease_ttl     = "768h"

# Enable the UI for easier management
ui = true