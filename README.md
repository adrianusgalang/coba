# tanyateguh

## Description

Slack bot for querying key metrics, built with [Hubot](https://hubot.github.com/docs/).

## SLO & SLI

- Availability: 99.9%

## Architecture Diagram

```
        chat request
Slack --------------> tanyateguh
  ^_____________________|
        chat response
```

## Links

- [Hubot](https://hubot.github.com/docs/)
- [Slack Developer Kit for Hubot](https://slackapi.github.io/hubot-slack/)

## Onboarding and Development Guide

1. Make sure you have [Node.js](https://nodejs.org/en/) and [npm](https://docs.npmjs.com/getting-started/installing-node) installed.
2. Clone this repo, then go to its root directory.
3. Run `npm install` to install all dependencies.

Then you can start tanyateguh locally by running:

    % bin/hubot --name tanyateguh

Use `tanyateguh help` to see all available commands.

    tanyateguh> tanyateguh help

## Deployment

1. update `TANYATEGUH_VERSION` in Makefile with datetime YYYYMMDDHHmm
2. run `make release`
