packer {
  required_plugins {
  }
}


variable "host_port_max" {
  type        = string
  default     = "4444"
  description = "Used for provisioning only."
}

variable "host_port_min" {
  type        = string
  default     = "2222"
  description = "Used for provisioning only."
}

variable "http_port_max" {
  type        = string
  default     = "9000"
  description = "Used for provisioning only."
}

variable "http_port_min" {
  type        = string
  default     = "8000"
  description = "Used for provisioning only."
}

variable "vm_name" {
  type    = string
  default = "ghidra-server"
}

variable "ssh_username" {
  type        = string
  default     = "ghidra"
  description = "Username used during provisioning and for the Ghidra Server service. Do not modify unless you also modify the service configuration."
}

variable "ssh_password" {
  type        = string
  default     = "root"
  sensitive   = true
  description = "SSH password for the ssh_username. Only used during provisioning. If you change this, then you MUST also modify ssh_password_crypted."
}

variable "ssh_password_crypted" {
  type        = string
  sensitive   = true
  default     = "$6$root$N8eFzhP5TW/1Wl1YXkIGagZroL.BmOIKvdCEdFDgndVp1uiOE6pZOZ8e.I/.50xHwXH03TeV0/gBC1ylGDzyJ0"
  description = "SSH password for the ssh_username, crypted for /etc/shadow (e.g. using mkpasswd --method=SHA-512 --stdin). Only used during provisioning. If you change this, then you MUST also modify ssh_password"
}

variable "ghidra_version" {
  type        = string
  default     = "10.1.2"
  description = "Ghidra version to install"
}

variable "ghidra_filename" {
  type        = string
  default     = "ghidra_10.1.2_PUBLIC_20220125.zip"
  description = "Name of the ZIP file, including suffix, containing the Ghidra build. Can be obtained from the Ghidra GitHub releases page. See README.md"
}

variable "hostname" {
  type        = string
  description = "Full hostname your VM should have"
}

variable "locale" {
  type    = string
  default = "en_US.UTF-8"
}

variable "keyboard" {
  type    = string
  default = "us"
}

variable "language" {
  type    = string
  default = "en"
}


source "qemu" "ubuntu" {
  iso_url          = "http://releases.ubuntu.com/20.04/ubuntu-20.04.4-live-server-amd64.iso"
  iso_checksum     = "sha256:28ccdb56450e643bad03bb7bcf7507ce3d8d90e8bf09e38f6bd9ac298a98eaad"
  shutdown_command = "echo '${var.ssh_password}' | sudo -S -- sh -c 'passwd -l ghidra && shutdown -P now'"
  disk_size        = "50000M"
  format           = "qcow2"
  accelerator      = "kvm"
  ssh_username     = var.ssh_username
  ssh_password     = var.ssh_password
  ssh_timeout      = "20m"
  host_port_max    = var.host_port_max
  host_port_min    = var.host_port_min
  http_content = {
    "/meta-data" = file("http/meta-data")
    "/user-data" = templatefile("http/user-data", {
      hostname             = var.hostname
      ssh_password_crypted = var.ssh_password_crypted
      ssh_password         = var.ssh_password_crypted
    })
  }
  http_port_max    = var.http_port_max
  http_port_min    = var.http_port_min
  vnc_bind_address = "0.0.0.0"
  vm_name          = var.vm_name
  net_device       = "virtio-net"
  disk_interface   = "virtio"
  memory           = 4096
  boot_wait        = "1s"
  boot_command = [
    " <esc><wait>",
    " <wait>",
    " <wait>",
    " <wait>",
    " <wait>",
    "<wait>",
    "<f6><wait><enter><wait>",
    "<esc><wait>",
    "<bs><bs><bs><bs><wait>",
    " autoinstall<wait5>",
    " ds=nocloud-net<wait5>",
    ";s=http://<wait5>{{.HTTPIP}}<wait5>:{{.HTTPPort}}/<wait5>",
    " ---<wait5>",
    "<enter><wait5>"
  ]
  headless = true
}


build {
  name = "ghidra-server"
  sources = [
    "source.qemu.ubuntu"
  ]

  provisioner "shell" {
    script = "install_context.sh"
    env = {
      DEBIAN_FRONTEND = "noninteractive",
    }
    execute_command = "echo '${var.ssh_password}' | sudo -S bash -c '{{ .Vars }} {{ .Path }}'"
  }

  provisioner "shell" {
    environment_vars = [
      "GHIDRA_VERSION=${var.ghidra_version}",
      "GHIDRA_FILENAME=${var.ghidra_filename}"
    ]
    script = "download_ghidra.sh"
  }

  provisioner "file" {
    source      = "server.conf"
    destination = "/home/ghidra/ghidra/server/server.conf"
  }

  provisioner "file" {
    source      = "jaas.conf"
    destination = "/home/ghidra/ghidra/server/jaas.conf"
  }

  provisioner "shell" {
    inline = ["apt update", "apt install --yes default-jre"]
    env = {
      DEBIAN_FRONTEND = "noninteractive"
    }
    execute_command = "echo '${var.ssh_password}' | sudo -S bash -c '{{ .Vars }} {{ .Path }}'"
  }

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | sudo -S bash -c '{{ .Vars }} {{ .Path }}'"
    inline          = ["bash /home/ghidra/ghidra/server/svrInstall"]
  }


}