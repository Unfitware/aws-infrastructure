# aws-infrastructure
Infrastructure as code for AWS

```
terraform/
  bootstrap/
    backend/
      main.tf
      variables.tf
      outputs.tf

  live/
    dev/
      network/
        backend.tf
        providers.tf
        main.tf
        variables.tf
      app/
        backend.tf
        providers.tf
        main.tf
        variables.tf
    prod/
      network/
      app/

  modules/
    vpc/
    s3/
    iam/
    lambda/
    ```
