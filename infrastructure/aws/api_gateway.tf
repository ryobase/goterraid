output "base_url" {
  value = "${aws_api_gateway_deployment.go_terra_id.invoke_url}"
}
