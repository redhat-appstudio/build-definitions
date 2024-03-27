# sast-snyk-check task

## Description:

The sast-snyk-check task uses Snyk Code tool to perform Static Application Security Testing (SAST) for Snyk, a popular cloud-native application security platform.

Snyk's SAST tool uses a combination of static analysis and machine learning techniques to scan an application's source code for potential security vulnerabilities, including common issues such as SQL injection, cross-site scripting (XSS), and code injection attacks.

> NOTE: This task is executed only if the user provides a Snyk token stored in a secret in their namespace. The name of the secret then needs to be supplied in the `snyk-secret` pipeline parameter.

## Params:

| name        | description                               |
|-------------|-------------------------------------------|
| SNYK_SECRET | Name of secret which contains Snyk token. |
| ARGS        | Append arguments.                         |

## How to obtain a snyk-token and enable snyk task on the pipeline:

Follow the steps given [here](https://redhat-appstudio.github.io/docs.appstudio.io/Documentation/main/how-to-guides/testing_applications/enable_snyk_check_for_a_product/)

## Results:

| name                  | description              |
|-----------------------|--------------------------|
| TEST_OUTPUT     | Tekton task test output. |

## Source repository for image:

https://github.com/redhat-appstudio/hacbs-test

## Additional links:

* https://snyk.io/product/snyk-code/
* https://snyk.io/
