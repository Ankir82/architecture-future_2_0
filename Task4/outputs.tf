output "catalog_container_name" {
  description = "Name of the running catalog container."
  value       = docker_container.catalog.name
}

output "storage_container_name" {
  description = "Name of the running storage container."
  value       = docker_container.storage.name
}

output "mc_container_name" {
  description = "Name of the running Minio Client container."
  value       = docker_container.mc.name
}


