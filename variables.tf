//Defining Variables

//Project ID Variable
variable "project_id" {
  type = string
  default = "sandbox-20210730-z4re8f"
}

//Region1 Variable
variable "region1" {
  type = string
  description = "Region1 Name"
  default = "us-central1"
}

//Region2 Variable
variable "region2" {
  type = string
  description = "Region2 Name"
  default = "us-east1"
}
