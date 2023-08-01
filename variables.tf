
variable "permission_boundary_name" {
  description = "Permission Boundary that needs to be attached to the Permission Sets incase it's not previously attached"
  type        = string
  default = "testpermissionboundary"
}
