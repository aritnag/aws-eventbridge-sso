# Eventbridge Attach Permission Sets to Permission Boundary Lambda Functions

## Conventions

The following tools and conventions are used within this project:

- [pipenv](https://github.com/pypa/pipenv) for managing Python dependencies and development virtualenv
- [pytest](https://github.com/pytest-dev/pytest) ) for unit testing

## Getting Started

The following instructions will help you get setup for local development and testing purposes.

### Prerequisites

#### [Pipenv](https://github.com/pypa/pipenv)

Pipenv is used to help manage the python dependencies and local virtualenv for local testing and development. To install `pipenv` please refer to the project [installation documentation](https://github.com/pypa/pipenv#installation).

Install the projects Python dependencies (with development dependencies) locally by running the following command.

```bash
  $ pipenv install --dev
```

If you add/change/modify any of the Pipfile dependencies, you can update your local virtualenv using:

```bash
  $ pipenv update
```

### Testing

#### Sample Payloads

In the `events/`  sample message payloads used for testing and validation:

1. In `events/` contains raw events as provided by AWS. You can see a more in-depth list of example events in the (AWS documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/EventTypes.html)


#### Unit Tests

There are a number of pipenv scripts that are provided to aid in testing and ensuring the codebase is formatted properly.

- `pipenv run test`: execute unit tests defined using pytest and show test coverage
- `pipenv run lint`: show linting errors and static analysis of codebase
- `pipenv run format`: auto-format codebase according to configurations provided
- `pipenv run imports`: auto-format import statements according to configurations provided
- `pipenv run typecheck`: show typecheck analysis of codebase

See the `[scripts]` section of the `Pipfile` for the complete list of script commands.
