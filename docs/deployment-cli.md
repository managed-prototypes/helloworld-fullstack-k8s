# Deployment via CLI

## Prerequisites

- [terraform](https://developer.hashicorp.com/terraform/install)
- [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (for TF S3 backend support)
- Configure AWS cli, using the `acces key` and `secret key` from DO

      ```sh
      aws configure --profile managed_prototypes
      ```

- Add an SSH key to DO team as `~/.ssh/managed_prototypes`
- Get the `local.tfvars` file with DO PAT token to the team (with write access)
- Just (for running commands)
  - `brew install just`

## Usage

```sh
just terraform/init

just terraform/plan

just terraform/apply

just terraform/show

just terraform/destroy
```

- Open http://web-k8s.prototyping.quest
