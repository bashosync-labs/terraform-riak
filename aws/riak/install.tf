resource "aws_instance" "primary" {
    ami = "${lookup(var.ami, concat(var.region, "-", var.platform))}"
    instance_type = "${var.instance_type}"
    key_name = "${var.key_name}"
    security_groups = ["${var.security_group_name}"]
    connection {
        user = "${lookup(var.user, var.platform)}"
        key_file = "${var.key_path}"
    }

    #Instance tags
    tags {
        Name = "riak-${var.product_version}-${var.platform}-0"
    }

    provisioner "remote-exec" {
        inline = [
	    "echo ${lookup(var.package, concat(var.product_version, "-", var.platform))} > /tmp/package",
        ]
    }

    provisioner "remote-exec" {
        scripts = [
            "${path.module}/bootstrap-${lookup(var.platform_base, var.platform)}.sh",
        ]
    }

}

resource "aws_instance" "secondary" {
    ami = "${lookup(var.ami, concat(var.region, "-", var.platform))}"
    instance_type = "${var.instance_type}"
    key_name = "${var.key_name}"
    count = "${var.nodes - 2}"
    security_groups = ["${var.security_group_name}"]

    connection {
        user = "${lookup(var.user, var.platform)}"
        key_file = "${var.key_path}"
    }

    #Instance tags
    tags {
        Name = "riak-${var.product_version}-${var.platform}-${count.index + 1}"
    }

    depends_on = ["aws_instance.primary"]

    provisioner "remote-exec" {
        inline = [
            "echo ${aws_instance.primary.private_ip} > /tmp/primary_ip",
            "echo ${lookup(var.package, concat(var.product_version, "-", var.platform))} > /tmp/package",
        ]
    }

    provisioner "remote-exec" {
        scripts = [
            "${path.module}/bootstrap-${lookup(var.platform_base, var.platform)}.sh",
	    "${path.module}/join.sh",
        ]
    }

}

resource "aws_instance" "final" {
    ami = "${lookup(var.ami, concat(var.region, "-", var.platform))}"
    instance_type = "${var.instance_type}"
    key_name = "${var.key_name}"
    security_groups = ["${var.security_group_name}"]
    connection {
        user = "${lookup(var.user, var.platform)}"
        key_file = "${var.key_path}"
    }

    #Instance tags
    tags {
	Name = "riak-${var.product_version}-${var.platform}-${var.nodes - 1}"
    }

    depends_on = ["aws_instance.secondary"]

    provisioner "remote-exec" {
        inline = [
            "echo ${aws_instance.primary.private_ip} > /tmp/primary_ip",
            "echo ${lookup(var.package, concat(var.product_version, "-", var.platform))} > /tmp/package",
        ]
    }

    provisioner "remote-exec" {
        scripts = [
            "${path.module}/bootstrap-${lookup(var.platform_base, var.platform)}.sh",
	    "${path.module}/join.sh",
	    "${path.module}/cluster.sh",
        ]
    }

}
