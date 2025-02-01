terraform init -backend-config=vars/dev.tfbackend
terraform apply -var-file=vars/dev.tfvars 



terraform init -backend-config=vars/prod.tfbackend
terraform apply -var-file=vars/prod.tfvars 

