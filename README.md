# OpenGood.io OSS Cloud-Native Pipeline

Centralized Concourse CI pipelines for all OpenGood.io OSS cloud-native project types

## Pipeline Generation

To make creating a pipeline as easy as possible, this repo provides centralized Concourse CI pipelines to generate a
pipeline based on a project type. In addition, a script is provided to automate the process of generating a pipeline.

### Supported Pipeline Project Types

| Project Type | Supported ? |
|:------------ |:----------- |
| App          | Yes         |
| Docker       | Yes         |

### Download Cloud-Native Pipeline Project

Download the **OpenGood.io cloud-native pipeline** from GitHub:

```bash
git clone https://github.com/opengood-io/cloud-native-pipeline
cd cloud-native-pipeline
```

### Generate Pipeline

To generate a pipeline, run:

```bash
bin/generate-pipeline.sh
```

One will be prompted by the script to enter values for the pipeline parameters:

| Parameter               | Description                                       | Example                  |
|:------------------------|:------------------------------------------------- |:------------------------ |
| type                    | Pipeline project type (see supported types above) | app                      |
| name                    | Pipeline project name                             | my-project               |
| concourseTeamName       | Concourse CI team name                            | my-team                  |
| username                | Concourse CI username                             | username                 |
| password                | Concourse CI password                             | password                 |

The script performs the following actions:

1. Captures all required input from a user to generate a pipeline
1. Combines shared and project pipeline parameters files
1. Authenticates with Concourse CI instance
1. Generates pipeline and sets its configuration in Concourse CI

## Pipeline Resource Credentials

Generated pipelines require credentials to access resources, such as GitHub, Docker Hub, Maven Central, etc. A script is
provided that automates the storing of credentials for resources used in generated pipelines.

### Supported Pipeline Credential Storage Types

| Project Type | Supported ? |
|:------------ |:----------- |
| Vault        | Yes         |
| YAML         | Yes         |

### Store Pipeline Resource Credentials

To store pipeline resource credentials, run:

```bash
bin/store-pipeline-credentials.sh
```

One will be prompted by the script to conditionally enter value(s) for credentials parameters:

| Parameter                          | Description                             | Example                      |
|:---------------------------------- |:--------------------------------------- |:---------------------------- |
| name                               | Pipeline project name                   | my-project                   |
| concourseTeamName                  | Concourse CI team name                  | my-team                      |
| githubUser                         | GitHub username                         | github-username              |
| githubToken                        | GitHub token                            | github-token                 |
| githubSharedPipelineEmail          | GitHub shared pipeline email            | user@domain.com              |
| githubSharedPipelineRepo           | GitHub shared pipeline repo             | shared-pipeline              |
| githubSharedPipelineRepoBranch     | GitHub shared pipeline repo branch      | master                       |
| githubProjectEmail                 | GitHub project email                    | user@domain.com              |
| githubProjectRepo                  | GitHub project repo                     | my-project                   |
| githubProjectRepoBranch            | GitHub project repo branch              | master                       |
| dockerUserName                     | Docker username                         | docker-user                  |
| dockerPassword                     | Docker password                         | docker-password              |
| pctApiEndpointUri                  | PCF API endpoint URI                    | https://api.run.pivotal.io   |
| pcfDomain                          | PCF domain name                         | cfapps.io                    |
| pcfOrg                             | PCF organization                        | my-org                       |
| pcfSpace                           | PCF space                               | my-space                     |
| pcfUserName                        | PCF username                            | pcf-user                     |
| pcfPassword                        | PCF password                            | pcf-password                 |
| dbUserName                         | Database username                       | db-user                      |
| dbPassword                         | Database password                       | db-password                  |
| mavenCentralUserName               | Maven Central username                  | maven-central-username       |
| mavenCentralPassword               | Maven Central password                  | maven-central-password       |
| mavenCentralGpgKeyRingName         | Maven Central GPG key ring name         | my-key-ring                  |
| mavenCentralGpgKeyRingComment      | Maven Central GPG key ring comment      | My GPG Key Ring              |
| mavenCentralGpgKeyRingEmail        | Maven Central GPG key ring email        | user@domain.com              |
| mavenCentralGpgKeyRingPassphrase   | Maven Central GPG key ring passphrase   | my-key-ring-passphrase       |

The script performs the following actions:

1. Captures all required input from a user to store credentials for pipeline resources
1. Prompts for credential storage type
1. Outputs all credentials information to be stored
1. If specified, generates SSH private/public keys for GitHub repo(s) deploy key(s)
1. If specified, generates GPG key ring(s) and secret keys for Maven Central artifact repo publishing
1. If Vault specified, stores all specified credentials information into Vault
1. If YAML specified, stores all specified credentials information into YAML credentials file
1. If specified, creates GitHub repo(s) deploy key(s) in GitHub for repo(s) via GitHub API

## Disclaimer

`cloud-native-pipeline` is a project from the OpenGood.io library of OSS projects, frameworks, and
solutions.