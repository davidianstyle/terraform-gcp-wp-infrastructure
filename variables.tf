//Defining Variables

//Project ID Variable
variable "project_id" {
  type = string
  default = "---YOUR_PROJECT_ID---"
}

//Region1 Variable
variable "region1" {
  type = string
  description = "Region1 Name"
  default = "us-west1"
}

//Region2 Variable
variable "region2" {
  type = string
  description = "Region2 Name"
  default = "us-central1"
}
