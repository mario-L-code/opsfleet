
# Innovate Inc. — AWS Architecture

> **Objective:** Secure, cost-aware, production-grade architecture on **AWS** for a React SPA + Flask API + PostgreSQL.  
> **Principles:** Multi-environment organizational units, multi-VPCs, scalable Kubernetes clusters, Secret Manager, ECR and GitHub for GitOps, multi-AZ DB, multi-region for disaster recovery.

---

## AWS Account Structure (Organizations)

Use **AWS Organizations** with consolidated billing and SSO.

Create one managemnet account with 3 organizational units: Developer, Staging and Production.
- Root account has no workload. It's used just for billing visualization, and SCP management.
    -   Enable AWS Config, GuardDuty, CloudTrail, AWS Budgets, Guard Rails.
- 3 separate accounts to isolate risk with SSO or Okta to log into each one of them.
    - Developer Account — sandbox environment for experimentation.
    - Staging Account — mirrors Production architecture for testing; security and networking settings match Production as closely as possible.
    - Production Account — only production workloads; strict IAM policies. Limited IAM roles and admins.
- Use consolidated billing for volume discounts.



## Network Design

Use different VPCs (dev, staging, production) for the 3 organizational units and one disaster recovery

- **VPCS** `us-east-1` 3 VPCs with non-overlapping CIDR blocks for VPC peering
    - Enable VPC Flow Logs.
    - Use **3 AZs** in each VPC for high availability.
    - Use 3 public and 3 private subets per VPC.
    - Place and Internet Gateway in a public subnet and 2 NAT gateways on 2 private subnets.
    - Place public and private route tables on public and private subnets.
    - Place load balancers in front of the VPCs with WAF or Network Firwalls.
    - Place EKS worker nodes and Postgres DB on private subnets.
    - Create everything in **Terraform** and version it on private repos on Github.
- **Disaster Recovery** `us-west-2`  1 VPC for backups/replication
    - Replicate Postgres DB in us-west-2 with daily data replication.
    - Create a warm standby to mimic production environment.
    - Use Route53 for failover to the warm standby if production goes down.


## Compute Platform
- **Create 3 EKS clusters** one for each account (dev, staging, prod)
    - Use m5.medium spot node groups to start off with. It's a balanced server. Adjust later.
    - Use different node pools for front end and back end wokloads.
    - Use multi-AZ control plane and worker nodes for high availability.
    - Add cluster add-ons CoreDNS, kube-proxy, VPC CNI or calico, metrics-server.
    - Use different namespaces for add-ons and apps. Not default namespace.
    - Use Prometheus/Grafana for metrics and ELK stack for logging.
    - Use External Secrets Operator to retrieve secrets from Secrets Manager.
    - Create a Horizontal Pod Autoscaler strategy to scale out pods if needed.
    - Let Karpenter scale out or scale in the servers depending on workload.
    - Create limits/requests on deployments to limit node usage per application.
    - Use NGNIX or and AWS ALB ingress controller with different paths to the front end or REST API backend.
    - Use WAF rules to filter bad traffic or control DDoS attacks.
    - Optional: Create a Cloudfront distribution to cache information and reduce traffic to EKS.
- - **Docker Containerization**
    - Use minimal base images (Alpine), multi-stage builds, vulnerability scanning (Qualys).
    - Create incrementl and versioned images inside ECR.
- **CI/CD Deployment**
    - Have developers deploy their applications on Github
    - Create workflows to package the application and send it to the ECR. Increment the versions.
    - Create workflows to pull the image from ECR and deploy it on the EKS. Have 5-10 replicas running
    - Workflows will deploy on feature branches and approved PRs. Can't deploy directly to staging or production.
    - To deploy to staging or production, approve merging from feature branch to main branch.
    - Optional: Use ArgoCD to deploy the image into EKS.
    - Use rolling or canary deployments with pod disruption budgets.
    - Implement liveness/readyness probes inside the deployments.


## Database
- **Requirement**: Highly available PostgreSQL server
    - Use RDS Postgres. AWS assures that it's highly reliable, fast and less expensive then Aurora.
    - Create one for the dev environemnt with minimal information.
    - Create another one for staging and production. Limit IAM roles that can access it.
    - Enable RDS encryption at rest and only private subnet security groups can communicate with it.
    - Deploy it as a multi-AZ with multi-read instances. It will failover to another AZ automatically. 
    - Enable storage autoscaling and enhanced monitoring for better monitoring. 
    - Create a separate multi-AZ database in `us-west-2` for disaster recovery. 
    - Use Cross-Region automated backups to copy snapshots daily into the second database.
    - Optional: Use RDS Proxy to decrease the ammount of connections to the database.



## Higher Level Considerations
   - **Incident Response**: PagerDuty on-call, comms via Slack, tickets via Jira.
   - **Coding**: Separate workspaces or folders per env 
   - **Testing**: Have developers create smoke tests for their apps.


## Deliverables Checklist

- [ ] AWS Org + SSO + SCP guardrails
- [ ] Central logging (CloudTrail/Config) & GuardDuty
- [ ] VPCs (dev/stage/prod) with endpoints, route tabkes, IGs and NAT Gateways
- [ ] EKS clusters + Karpenter + core add-ons (ALB Controller, ExternalDNS, cert-manager, metrics)
- [ ] GitOps (Argo CD) + Rollouts; CI pipelines to ECR, HPAs
- [ ] CloudFront, WAF, ACM certs, Route 53
- [ ] RDS PostgreSQL Multi-AZ, backups, cross-region snapshots
- [ ] Observability (Logs/Metrics/Tracing/Dashboards/Alerts)
- [ ] Cost budgets/alarms & tagging
