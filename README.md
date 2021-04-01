# terraform-gcp-wp-infrastructure
This Repository Contains Terraform Code to Deploy WordPress on GCP Infrastructure
_Updated for Terraform 0.12+, and integrates Google Secret Manager_

## Prerequisites
1. [Terraform](https://www.terraform.io/downloads.html) should be installed and added to your PATH.
2. [gcloud SDK](https://cloud.google.com/sdk/docs/install) should be installed and initialized.
    * It is _strongly_ recommended that you create a new Google Cloud project for your Terraform deployment!
3. Replace the **gcpCreds.json** file with your [Service Account](https://cloud.google.com/iam/docs/creating-managing-service-accounts) key file.
4. Make sure your Service Account has the following roles:
    * Editor
    * Kubernetes Engine Admin
    * Secret Manager Admin
5. Add the following secrets to [Google Secret Manager](https://cloud.google.com/secret-manager):
    * root_pass
    * database
    * db_user
    * db_user_pass
6. In **variables.tf** Replace the Project ID placeholder with your own Project ID.  

## Usage
First Download or Clone this repo to your local system.  Then:  
To Initiate Terraform WorkSpace       : **terraform init**
To create infrastructure, run command : **terraform apply -auto-approve**
To delete infrastructure, run command : **terraform destroy -auto-approve**
