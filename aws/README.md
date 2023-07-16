# AWS

## Setting up a new account with mfa in aws-vault

### 1. Add profile to `~/.aws/config`

Add a line that looks like this:
```
[profile jonsmith]
region = eu-west-2
mfa_serial = arn:aws:iam::<account id>:mfa/jonsmith
credential_process = aws-vault exec jonsmith --json --prompt=osascript
```

### 2. Store credentials in aws-vault

```bash
$ aws-vault add jonsmith
Enter Access Key Id: ABDCDEFDASDASF
Enter Secret Key: %%%
```
