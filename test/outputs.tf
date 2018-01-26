output "blog-fg-url" {
  value = "${module.blog-fg.service_url}"
}

output "blog-ecs-url" {
  value = "${module.blog-ecs.service_url}"
}
