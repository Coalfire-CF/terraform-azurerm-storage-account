# Checkov PR Scan GitHub Action

This GitHub Action automatically scans Terraform files in pull requests using Checkov, a tool for infrastructure as code (IaC) security and compliance scanning. The action posts the results of the Checkov scan as a comment on the pull request.

## Overview

The action performs the following steps:

1. Checks out the repository.
2. Sets up Python.
3. Installs Checkov.
4. Gets a list of changed Terraform files in the pull request.
5. Runs Checkov on the changed Terraform files.
6. Creates a comment with Checkov results on the pull request.
7. (Optional) Sends a Slack notification with the status of the Checkov scan.

## Detailed Steps

1. **Checkout repository**: The `actions/checkout@v2` action is used to check out the repository with a fetch depth of 0 and the pull request's head reference.

2. **Set up Python**: The `actions/setup-python@v2` action is used to set up Python 3.x.

3. **Install Checkov**: The `pip install checkov` command is used to install Checkov.

4. **Get changed Terraform files**: The `git diff` command is used to get a list of changed Terraform files in the pull request. The output is set as a step output called `files`.

5. **Run Checkov**: This step iterates through the changed Terraform files, runs Checkov with JSON output, and aggregates the results of failed checks. The results are stored in the `CHECKOV_OUTPUT` environment variable, and a boolean flag, `CHECKOV_PASSED`, is set to indicate whether all checks passed.

6. **Create comment with Checkov results**: The `actions/github-script@v5` action is used to create a comment on the pull request with the Checkov scan results. The comment includes a table with the following columns: Check ID, Description, File, Resource, and Checkov Result. If all checks passed, the comment indicates that all checks passed.

7. **(Optional) Send Slack notification**: If you'd like to send a Slack notification with the status of the Checkov scan, follow the instructions in the previous answer to set up a Slack Incoming Webhook and add the provided step after the "Create comment with Checkov results" step in your GitHub Actions workflow.

## Logic and Commands

- The `git diff` command is used to get the list of changed Terraform files in the pull request.

- The `IFS=$'\n' read -ra FILES` command is used to split the changed Terraform files into an array.

- The `checkov -f "$file" --output json || true` command is used to run Checkov on each changed Terraform file with JSON output. The `|| true` part ensures that the action continues even if Checkov returns a non-zero exit code.

- The `python -c "import sys, json; print(json.dumps(sys.stdin.read()))"` command is used to escape the JSON output from Checkov so that it can be used in the shell script.

- The `python -c "import json; a=json.loads('$RESULTS'); b=json.loads($OUTPUT_ESCAPED); a.extend(b['results']['failed_checks']); print(json.dumps(a))"` command is used to merge the JSON results from multiple Checkov scans.

Please let me know if you have any questions or need further clarification.
