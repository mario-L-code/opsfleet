# Innovate Inc. — AWS Architecture

> **Objective:** Secure, cost-aware, production-grade architecture on **AWS** for a React SPA + Flask API + PostgreSQL.  
> **Principles:** Multi-environment organizational units, multi-VPCs, scalable Kubernetes clusters, Secrets Manager, ECR and GitHub for GitOps, multi-AZ DB, multi-region disaster recovery.

---

<div style="width: 640px; height: 480px; margin: 10px; position: relative;"><iframe allowfullscreen frameborder="0" style="width:640px; height:480px" src="https://lucid.app/documents/embedded/219dc40d-f232-4f9a-a77c-980e3e69c5c3" id="th7G6LIN1vns"></iframe></div>


## AWS Account Structure (Organizations)

Use **AWS Organizations** with consolidated billing and SSO.

- **Root (Management) Account**: No workloads; used for billing visualization, SCP management, AWS Config, GuardDuty, CloudTrail, AWS Budgets, and guardrails.  
- **Developer Account**: Sandbox environment for experimentation; limited guardrails but IAM policies enforce security and cost.  
- **Staging Account**: Mirrors Production architecture; security and networking settings match Production.  
- **Production Account**: Only production workloads; strict IAM policies with minimal admin access.  

> All accounts use consolidated billing to benefit from volume discounts. Identity is centralized via SSO or Okta.

---

## Network Design

- **VPCs per environment** (`dev`, `staging`, `prod`) in `us-east-1` with non-overlapping CIDR blocks to allow future VPC peering.  
  - **3 AZs per VPC** for high availability.  
  - **Subnets:** 3 public (for ALB/NAT) and 3 private (for EKS nodes and RDS).  
  - **Routing:** Internet Gateway in public subnets, 2 NAT Gateways in private subnets; route tables per subnet type.  
  - **Security:** Security Groups for pods and DB, NACLs for subnet-level filtering.  
  - **Ingress & WAF:** ALB Ingress Controller with AWS WAF for L7 protection; optional Network Firewall for L3/L4 inspection.  
  - **Private endpoints:** Use VPC Endpoints for S3, ECR, and other AWS services.  
  - **Logging:** Enable VPC Flow Logs.  

- **Disaster Recovery VPC** in `us-west-2`  
  - Warm standby setup to mimic production.  
  - Replicate PostgreSQL database daily via cross-region snapshots.  
  - Route53 health checks and failover to DR if production fails.

---

## Compute Platform

- **EKS Clusters**  
  - One cluster per account (dev, staging, prod).  
  - Multi-AZ control plane and worker nodes for HA.  
  - **Node groups:**  
    - m5.medium spot instances to start; scale with Karpenter.  
    - Separate node pools for frontend and backend workloads.  
    - Node labels/taints for workload segregation.  
  - **Cluster add-ons:** CoreDNS, kube-proxy, VPC CNI or Calico, metrics-server.  
  - **Namespaces:** Separate for system add-ons and applications.  
  - **Observability:** Prometheus + Grafana for metrics, ELK stack for logging.  
  - **Secrets:** External Secrets Operator integrates with Secrets Manager.  
  - **Autoscaling:** Horizontal Pod Autoscaler for pods; Karpenter scales nodes.  
  - **Resource limits/requests** to prevent noisy neighbor issues.  
  - **Ingress:** ALB Ingress Controller with path-based routing (`/` → SPA, `/api` → REST API).  
  - **Security:** AWS WAF for DDoS protection, Pod Security Standards enforced.  
  - **Optional:** CloudFront distribution in front of ALB for caching.

- **Docker Containerization**
  - Minimal base images (Alpine), multi-stage builds, vulnerability scanning.  
  - Versioned, incremental images stored in ECR.

- **CI/CD & GitOps**
  - Developers push to GitHub; workflows package, scan, and push images to ECR.  
  - Deployments pull images from ECR to EKS; 5–10 replicas per service.  
  - Feature branches deploy to dev/staging; main branch merges trigger production.  
  - Optional: ArgoCD for GitOps-based deployments.  
  - Deployment strategies: rolling or canary with PodDisruptionBudgets.  
  - Health: Liveness and readiness probes implemented.

---

## Database

- **Requirement:** Highly available PostgreSQL server using **RDS**.  
  - Dev: smaller instance with minimal data.  
  - Staging/Prod: multi-AZ with read replicas, limited IAM roles.  
  - **Security:** Private subnet, Security Groups, IAM authentication, encrypted at rest (KMS), SSL/TLS for in-transit.  
  - **Monitoring:** Enhanced Monitoring enabled; storage autoscaling.  
  - **Disaster Recovery:** Multi-AZ in `us-west-2` for warm standby; cross-region automated snapshot backups daily.  
  - Optional: RDS Proxy to manage connection pooling.  
  - Optional: Parameter tuning and minor version upgrades tested in staging before production.

---

## Higher-Level Considerations

- **Incident Response:** PagerDuty on-call, Slack for communications, Jira for ticketing.  
- **Coding & Testing:** Separate workspaces/folders per environment; smoke tests for every feature.  
- **Observability:** Logs, metrics, dashboards, alerts for CPU, memory, pod failures, node scaling, replication lag.

---

## Deliverables Checklist

- [ ] AWS Organizations + SSO + SCP guardrails  
- [ ] Centralized logging & monitoring (CloudTrail, Config, GuardDuty)  
- [ ] VPCs (dev/stage/prod) with endpoints, route tables, IGs, NAT Gateways  
- [ ] EKS clusters + Karpenter + add-ons (ALB Controller, ExternalDNS, cert-manager, metrics)  
- [ ] GitOps (ArgoCD) + CI pipelines to ECR, HPAs  
- [ ] CloudFront, WAF, ACM certificates, Route 53  
- [ ] RDS PostgreSQL multi-AZ, read replicas, cross-region backups  
- [ ] Observability (Logs, Metrics, Tracing, Dashboards, Alerts)  
- [ ] Security (Secrets Manager, IAM roles, Pod Security Policies)  
- [ ] Cost control (Budgets, Alarms, Tagging)
