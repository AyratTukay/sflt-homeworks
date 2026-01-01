terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  # token                    = "do not use!!!"
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  service_account_key_file = file("~/.authorized_key.json")
}

resource "yandex_vpc_network" "network" {
  name = "load-balancer-network"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "load-balancer-subnet"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
  zone = "ru-central1-a"
}

resource "yandex_compute_instance" "web_server" {
  count = 2
  name = "web-server-${count.index + 1}"
  zone = "ru-central1-a"

  boot_disk {
    initialize_params {
      image_id = "fd833v6c5tb0udvk4jo6"
      size = 10
    }
  }
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat = true
  }
  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }
}

# Создание таргет группы
resource "yandex_lb_target_group" "my_tg" {
  name = "my-tg-example"
  region_id = "ru-central1"

  dynamic "target" {
    for_each = yandex_compute_instance.web_server
    content {
      subnet_id = yandex_vpc_subnet.subnet.id
      address   = target.value.network_interface[0].ip_address
    }
  }
}

# Балансировщик нагрузки
resource "yandex_lb_network_load_balancer" "lb" {
  name = "lb-example"
  listener {
    name = "http-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }
  attached_target_group {
    target_group_id = yandex_lb_target_group.my_tg.id
    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}