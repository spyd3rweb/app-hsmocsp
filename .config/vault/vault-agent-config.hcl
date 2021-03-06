exit_after_auth = false
pid_file = "/app/.config/vault/pidfile"

auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes"
        config = {
            role = "ocsp"
        }
    }

    sink "file" {
        config = {
            path = "/app/.config/vault/.vault-token"
        }
    }
}

cache {
    use_auto_auth_token = true
}

listener "tcp" {
    address = "127.0.0.1:8007"
    tls_disable = true
}

vault {
    address = "http://127.0.0.1:8200"
}