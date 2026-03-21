# Azure Pipeline Setup

## What changed
- The pipeline now builds a Docker-based Odoo 18 VM bundle instead of cloning source code directly onto the VM.
- The build output is published as Azure Pipeline artifacts.
- Staging and production deployments now copy the built bundle to the VM and start it with Docker Compose.

## Automatic pipeline runs
- The new `azure-pipelines.yml` uses Microsoft-hosted `ubuntu-latest` agents by default.
- That means you do not need to keep a local agent terminal window running for normal builds and deployments.
- Pushes to `Staging` trigger the staging deployment stage.
- Pushes to `master` trigger the production deployment stage.

## When you still need a self-hosted agent
- If your VM cannot be reached over SSH from a Microsoft-hosted agent, keep a self-hosted agent.
- In that case, run the agent as a service so it starts automatically after reboot instead of needing an interactive terminal session.

## Azure DevOps items you need to configure
1. Create or update the SSH service connections referenced by `stagingSshEndpoint` and `productionSshEndpoint` in `azure-pipelines.yml`.
2. Make sure the VM has Docker Engine and Docker Compose installed.
3. On the first deployment, review `.env.vm` on the VM after the pipeline copies the bundle.
4. If staging and production use different hosts or paths, update the variables at the top of `azure-pipelines.yml`.

## Recommended first run
1. Commit the pipeline changes.
2. In Azure DevOps, create the pipeline from `azure-pipelines.yml`.
3. Run the pipeline manually once.
4. Confirm the build artifact appears.
5. Confirm the VM receives the bundle in `/opt/odoo18/staging` or `/opt/odoo18/production`.
6. Edit `.env.vm` on the VM if you need non-default ports or credentials.

## Official Microsoft guidance
- Azure Pipelines agents overview: https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/agents?view=azure-devops
- Microsoft says Microsoft-hosted agents are usually the simplest starting point, and self-hosted agents should be run as a service for reliable production use.
