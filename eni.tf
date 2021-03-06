locals {
  additional_ips_count = var.associate_public_ip_address && var.instance_enabled && var.additional_ips_count > 0 ? var.additional_ips_count : 0
}

resource "aws_network_interface" "additional" {
  count     = local.additional_ips_count * var.instance_count
  subnet_id = var.subnet

  security_groups = compact(
    concat(
      [
        var.create_default_security_group ? join("", aws_security_group.default.*.id) : ""
      ],
      var.security_groups
    )
  )

  tags       = module.label.tags
  depends_on = [aws_instance.default]
}

resource "aws_network_interface_attachment" "additional" {
  count                = local.additional_ips_count * var.instance_count
  instance_id          = aws_instance.default.*.id[count.index % var.instance_count]
  network_interface_id = aws_network_interface.additional.*.id[count.index]
  device_index         = 1 + count.index
  depends_on           = [aws_instance.default]
}

resource "aws_eip" "additional" {
  count             = local.additional_ips_count * var.instance_count
  vpc               = true
  network_interface = aws_network_interface.additional.*.id[count.index]
  depends_on        = [aws_instance.default]
}
