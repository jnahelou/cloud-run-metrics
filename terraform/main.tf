terraform {
  experiments = [module_variable_optional_attrs]
}

variable "service_name" {
  type = string
}
