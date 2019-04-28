variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "DOMSERVER_INSTANCE_TYPE" {}
variable "JUDGEHOST_INSTANCE_TYPE" {}
variable "JUDGEHOST_COUNT" {}

provider "aws" {
  region = "us-east-1"
  access_key = "${var.AWS_ACCESS_KEY}"
  secret_key = "${var.AWS_SECRET_KEY}"
}

resource "aws_key_pair" "domjudge-key" {
  key_name = "domjudge-key"
  public_key = "${file("domjudge-key.pub")}"
}

resource "aws_instance" "domserver" {
  ami = "ami-0a313d6098716f372"
  instance_type = "${var.DOMSERVER_INSTANCE_TYPE}"
  key_name = "${aws_key_pair.domjudge-key.key_name}"
  tags {
    name = "domserver"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y python",
    ]
    connection {
      type = "ssh"
      user = "ubuntu"
      agent = false
      private_key = "${file("domjudge-key")}"
    }
  }
}

resource "aws_instance" "judgehost" {
  ami = "ami-0a313d6098716f372"
  instance_type = "${var.JUDGEHOST_INSTANCE_TYPE}"
  key_name = "${aws_key_pair.domjudge-key.key_name}"
  count = "${var.JUDGEHOST_COUNT}"
  tags {
    name = "judgehost-${count.index + 1}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y python",
    ]
    connection {
      type = "ssh"
      user = "ubuntu"
      agent = false
      private_key = "${file("domjudge-key")}"
    }
  }
}

data "template_file" "ansible_inventory" {
  template = "${file("${path.module}/templates/hosts.cfg")}"
  depends_on = [
    "aws_instance.domserver",
    "aws_instance.judgehost",
  ]
  vars {
    domserver_ips = "${aws_instance.domserver.public_ip}"
    judgehost_ips = "${join("\n", aws_instance.judgehost.*.public_ip)}"
  }
}

resource "null_resource" "ansible_inventory" {
  triggers {
    template_rendered = "${data.template_file.ansible_inventory.rendered}"
  }
  provisioner "local-exec" {
    command = "echo '${data.template_file.ansible_inventory.rendered}' > hosts"
  }
}

data "template_file" "ansible_variables" {
  template = "${file("${path.module}/templates/vars.yml.cfg")}"
  depends_on = [
    "aws_instance.domserver",
    "aws_instance.judgehost",
  ]
  vars {
    domserver_domain = "${aws_instance.domserver.public_ip}"
  }
}

resource "null_resource" "ansible_variables" {
  triggers {
    template_rendered = "${data.template_file.ansible_variables.rendered}"
  }
  provisioner "local-exec" {
    command = "echo '${data.template_file.ansible_variables.rendered}' > vars.yml"
  }
}