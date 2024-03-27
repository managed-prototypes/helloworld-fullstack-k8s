# Deployment via CLI

## Prerequisites

- [terraform](https://developer.hashicorp.com/terraform/install)
- [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (for TF S3 backend support)
- Configure AWS cli, using the `acces key` and `secret key` from DO

  ```sh
  aws configure --profile managed_prototypes
  ```

- Get the `local.tfvars` file with DO PAT token to the team (with write access)
- [just](https://just.systems)
- [k9s](https://k9scli.io)

## Usage

```sh
just terraform/init

just terraform/apply

just terraform/destroy

just # List all commands
```

For manual `kubectl` usage

```sh
just terraform/apply-and-kubectl

just terraform/check-kubectl
```

- Open http://test-subdomain-5.prototyping.quest
