# terraform-gcp-wp-infrastructure
This Repository Contains Terraform Code to Deploy WordPress on GCP Infrastructure.  
_Updated for Terraform 0.12+_  
_Now integrates Application Default Credentials and Google Secret Manager._  

## Prerequisites
1. [Terraform](https://www.terraform.io/downloads.html) should be installed and added to your PATH.
2. [gcloud SDK](https://cloud.google.com/sdk/docs/install) should be installed and initialized.
    * *It is _strongly_ recommended that you create a new Google Cloud project for your Terraform deployment!
3. Make sure you (or your Service Account) have the following roles:
    * Editor
    * Kubernetes Engine Admin
    * Secret Manager Admin
4. Run the command: ```gcloud auth application-default login``` to authenticate using [ADC](https://cloud.google.com/sdk/gcloud/reference/auth/application-default).
5. Make sure the following APIs are enabled on your project:
    * [Google Compute Engine](https://console.cloud.google.com/apis/api/compute.googleapis.com)
    * [Google Kubernetes Engine](https://console.cloud.google.com/apis/api/container.googleapis.com)
    * [Google Cloud SQL](https://console.cloud.google.com/apis/api/sqladmin.googleapis.com)
    * [Google Secret Manager](https://console.cloud.google.com/apis/api/secretmanager.googleapis.com)
    * [Stackdriver](https://console.cloud.google.com/apis/library/stackdriver.googleapis.com)
6. Add the following secrets to [Google Secret Manager](https://cloud.google.com/secret-manager):
    * root_pass
    * database
    * db_user
    * db_user_pass
7. In **variables.tf** replace ```---YOUR_PROJECT_ID---``` with your own Project ID.  

## Usage
Download or Clone this repo to your local system, then...  
To initiate Terraform WorkSpace           : ```terraform init```  
To create infrastructure, run command     : ```terraform apply -auto-approve```  
To delete infrastructure, run command     : ```terraform destroy -auto-approve```

## Authenticating with a Service Account (optional)
This module has been updated to use [Application Default Credentials](https://cloud.google.com/docs/authentication/production).  It no longer stores your key file in your project and will instead authenticate automatically with credentials set using ```gcloud auth```.  You can optionally specify a Service Account rather than authenticating with your own credentials using these steps:  
1. Create a [Service Account](https://cloud.google.com/iam/docs/creating-managing-service-accounts).
2. Make sure the Service Account has the roles specified in the Prerequisites.
3. Create and download a key file for your new Service Account and store them **outside your project**.
4. Set the [GOOGLE_APPLICATION_CREDENTIALS](https://cloud.google.com/docs/authentication/production#passing_variable) environment variable.
