resource "null_resource" "docker_build" {

    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        command = "docker build -t ${var.image_tag} --file ${var.path_to_src}/Dockerfile ${var.path_to_src}"
    }
}

resource "null_resource" "docker_login" {

    depends_on = [ null_resource.docker_build ]

    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        command = "docker login --username ${var.username} --password ${var.password}"
    }
}

resource "null_resource" "docker_push" {

    depends_on = [ null_resource.docker_login ]

    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        command = "docker push ${var.image_tag}"
    }
}

locals {
    dockercreds = {
        auths = {
            "hub.docker.com" = {
                auth = base64encode("${var.username}:${var.password}")
            }
        }
    }
}

resource "kubernetes_secret" "docker_credentials" {
    metadata {
        name = "docker-credentials"
    }

    data = {
        ".dockerconfigjson" = jsonencode(local.dockercreds)
    }

    type = "kubernetes.io/dockerconfigjson"
}
