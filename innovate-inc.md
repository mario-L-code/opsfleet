
# Innovate Inc. — AWS Architecture

> **Objective:** Secure, cost-aware, production-grade architecture on **AWS** for a React SPA + Flask API + PostgreSQL.  
> **Principles:** Managed services first, least privilege, GitOps, autoscaling, multi-AZ resilience, and paved-road defaults.

---

## 1) AWS Account Structure (Organizations)

Use **AWS Organizations** with consolidated billing and SSO. Separate accounts to isolate risk and costs.

- **foundations** — Org management, SSO, guardrails, centralized logs
- **network** (optional) — Shared networking (if centralizing VPCs/Transit Gateway)
- **dev**, **staging**, **prod** — Workload accounts (strong isolation of data & access)
- **security** (optional) — SIEM/forensics tooling, delegated admin for GuardDuty/Security Hub
- **analytics** (later) — BI/ETL workloads

**Guardrails & Central Services (in `foundations`):**
- **CloudTrail (org trail)** → centralized S3 log bucket + S3 Object Lock (WORM) + KMS
- **AWS Config (org)** → rules for drift/compliance
- **Security Hub + GuardDuty** (delegated admin) → findings aggregation
- **Service Control Policies (SCPs):** block non-compliant regions, restrict root, require tags, deny public S3
- **IAM Identity Center (SSO):** short-lived access; permission sets (read-only, devops, security-admin)

---

## 2) Regional & AZ Strategy

- **Primary:** `us-east-1` (broad service coverage, cost-effective)
- **DR Pair:** `us-west-2` (cross-region backups/replication)
- **AZs:** Use **3 AZs** in each VPC for high availability

---

## 3) Networking (per environment account)

**VPC (e.g., `10.20.0.0/16`)**  
Subnets (per 3 AZs):
- **Public Subnets:** ALB, NAT Gateways (one per AZ), VPC endpoints where allowed
- **Private App Subnets:** **EKS worker nodes** and app pods
- **Private DB Subnets:** **RDS PostgreSQL** Multi-AZ

**Egress & Endpoints:**
- NAT per AZ for resilience
- **Interface/Gateway VPC Endpoints:** S3, ECR (api+dkr), STS, CloudWatch Logs, Secrets Manager, SSM — reduces NAT cost & improves security

**Ingress Path:**
`CloudFront (OAC) + WAF` → `ALB (Ingress Controller)` → `EKS Services`

**Network Security:**
- **AWS WAF:** Managed rules (OWASP Top 10), rate limiting, IP allow/deny (as needed)
- **Security Groups:** ALB → API pods (target group), API → RDS:5432; least privilege
- **Network ACLs:** Simple stateless guardrails (documented rules)
- **K8s NetworkPolicies:** Calico/Cilium to restrict pod-to-pod/db access
- **No SSH:** Use **AWS Systems Manager Session Manager**

```mermaid
flowchart LR
  U[End Users] --> CF[CloudFront + WAF]
  CF -->|/ (SPA)| S3[S3 (Private, OAC)]
  CF -->|/api/*| ALB[Public ALB (LB Controller)]
  ALB --> EKS[(Amazon EKS)]
  EKS --> API[Flask API Pods]
  API --> RDS[(Amazon RDS PostgreSQL Multi-AZ)]
  EKS --> ECR[ECR (Private Registry)]
  EKS --> CW[CloudWatch / AMP / X-Ray]
```
---

## 4) Compute — Amazon EKS

**Control Plane:** Managed (multi-AZ), version N-1, managed add-ons (VPC CNI, CoreDNS, KubeProxy).  
**Ingress:** AWS Load Balancer Controller → ALB; NLB for special protocols.  
**DNS:** **ExternalDNS** updates Route 53 records from Ingress/Service annotations.  
**TLS:** **cert-manager** (ACM DNS-validated certs for ALB/CloudFront).

### Nodes & Autoscaling

- **Provisioning:** **Karpenter** (preferred) for just-in-time nodes
- **Capacity Mix:** On-Demand baseline + **Spot** for burst; **x86 + Arm64** where compatible
- **Families:** `m`, `c`, `r` instance types (exclude GPUs until needed)
- **Topologies:** 3 AZs, **PodDisruptionBudgets** and **topologySpreadConstraints**
- **Autoscaling Layers:**
  - **HPA** for workload replicas (CPU/Memory/custom metrics)
  - **Karpenter** (or Cluster Autoscaler) for nodes
- **Security:** **IRSA** (IAM Roles for Service Accounts), **Pod Security Standards** (`restricted`), `seccompProfile: RuntimeDefault`, read-only FS

**Karpenter NodePool Example:**
```yaml
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: general
spec:
  template:
    spec:
      requirements:
        - key: "karpenter.sh/capacity-type"
          operator: In
          values: ["on-demand","spot"]
        - key: "kubernetes.io/arch"
          operator: In
          values: ["amd64","arm64"]
        - key: "node.kubernetes.io/instance-type"
          operator: In
          values: ["m7g.large","m7i.large","c7g.large","c7i.large","r7g.large","r7i.large"]
  disruption:
    consolidationPolicy: WhenUnderutilized
```
---

## 5) Application Edge & Routing

- **React SPA:** S3 (private) + **CloudFront** OAC; compressions, caching, invalidations on deploy
- **API Hostname:** `api.innovate.example.com` via **Route 53**
- **Certificates:** **AWS Certificate Manager (ACM)** for CloudFront and ALB
- **WAF:** Attach to CloudFront (global) for broad protection and lower latency

**Ingress Example (ALB):**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
  rules:
    - host: api.innovate.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api
                port:
                  number: 8080
```
---

## 6) Database — Amazon RDS for PostgreSQL

- **Engine:** RDS PostgreSQL (Multi-AZ), starting at modest instance class with GP3 storage
- **Backups:** Automated backups with **PITR**; retention 7–30 days by env
- **Snapshots:** **Cross-region** snapshot copies nightly for DR
- **Encryption:** KMS at rest; TLS in transit; SG allow only from API pods/node SG
- **HA/Failover:** Built-in AZ failover; test quarterly
- **Scaling:** Read Replicas for analytics or heavy read traffic; pgbouncer (as needed)
- **Maintenance:** Minor auto-upgrades in window; performance insights enabled

**DR Strategy:**
- **Baseline:** Cross-region snapshots + IaC to recreate EKS/RDS → **RTO: hours, RPO: minutes**
- **Enhanced (future):** Aurora PostgreSQL Global Database for sub-minute RPO

---

## 7) CI/CD on AWS

- **Code Hosts:** GitHub or GitLab; OIDC to assume deploy roles (no long-lived keys)
- **Build:** Docker images → test → scan (Trivy) → push to ECR → generate SBOM
- **Deploy:** GitOps (Argo CD) sync; Rollouts canary (progressive delivery)
- **Environment Promotion:** PR-based; staging smoke tests; manual approval to prod

---

## 8) Observability

- **Logs:** App stdout → **CloudWatch Logs**; retention per env; subset shipped to OpenSearch if needed
- **Metrics:** **Amazon Managed Prometheus (AMP)** + **Amazon Managed Grafana (AMG)**; HPA feeds
- **Tracing:** OpenTelemetry SDK → X-Ray/ADOT collector
- **Alerts:** CloudWatch/AMP alerts on SLOs (latency, error rate, saturation), paging prod only

---

## 9) Security Hardening

- **Identity:** SSO; least-privilege permission sets; break-glass account with MFA
- **KMS Everywhere:** S3, EBS, RDS, ECR, CloudWatch Logs
- **Policy-as-Code:** OPA/Gatekeeper (deny unsigned images, root user, hostPath, NET_RAW)
- **Runtime:** Falco/Kubearmor (optional) for syscall anomalies
- **Patching:** Managed add-ons; node AMIs via Bottlerocket or EKS Optimized, weekly rotation
- **WAF/Shield:** Managed rules; token-based bot control (optional)
- **Data Access:** Production data access via ephemeral, audited roles; no direct DB users for humans

---

## 10) Cost Controls

- **Small baseline + autoscale:** HPA + Karpenter; **Spot** for burstable, stateless pools
- **NAT Optimization:** VPC endpoints; consolidate egress; prefer private links
- **Storage Lifecycle:** S3/ECR log and artifact TTLs; right-size RDS storage
- **Budgets & Alarms:** Account-level budgets; anomaly detection; cost allocation tags
- **Savings Plans/RI:** Commit after 1–3 months of steady-state data

---

## 11) Infrastructure as Code (Terraform)

- **State:** S3 remote state (foundations) + DynamoDB lock, KMS encryption
- **Modules:** `vpc`, `eks`, `karpenter`, `alb_controller`, `external_dns`, `cert_manager`, `external_secrets`, `rds`, `cloudfront_s3_spa`, `waf`, `route53`
- **Promotion:** Separate workspaces or folders per env; plan/apply via PR; scheduled `plan` for drift

---

## 12) High-Level Diagram (Mermaid)

```mermaid
graph TB
  subgraph Internet
    U[Users]
  end

  subgraph Edge[AWS Edge (Global)]
    CF[CloudFront + WAF]
  end

  subgraph VPC[Env VPC (3 AZs)]
    ALB[ALB (Ingress Controller)]
    EKS[(EKS Cluster)]
    RDS[(RDS PostgreSQL Multi-AZ)]
    NAT[NAT Gateways x3]
    EP[VPC Endpoints]
  end

  U --> CF
  CF -->|SPA| S3[S3 Private Bucket (OAC)]
  CF -->|/api/*| ALB
  ALB --> EKS
  EKS --> API[Flask API Deployments]
  API --> RDS
  EKS --> CW[CloudWatch / AMP / AMG / X-Ray]
  EKS --> ECR[ECR (Private Registry)]
```
---

## 13) Operational Runbooks (Initial)

- **Rollback:** Argo Rollouts → abort canary → promote stable
- **Node Issues:** Drain via PDBs; Karpenter re-provisions
- **RDS Failover:** Validate app reconnect; check connection pools; observe replication lag
- **Incident Response:** PagerDuty on-call; SEV playbooks; comms via Slack + status page

---

## 14) Deliverables Checklist

- [ ] AWS Org + SSO + SCP guardrails (foundations)
- [ ] Central logging (CloudTrail/Config) & Security Hub/GuardDuty
- [ ] VPCs (dev/stage/prod) with endpoints, NAT per AZ
- [ ] EKS cluster + Karpenter + core add-ons (ALB Controller, ExternalDNS, cert-manager, metrics)
- [ ] GitOps (Argo CD) + Rollouts; CI pipelines to ECR
- [ ] CloudFront+S3 SPA, WAF, ACM certs, Route 53
- [ ] RDS PostgreSQL Multi-AZ, backups, PITR, cross-region snapshots
- [ ] Observability (Logs/Metrics/Tracing/Dashboards/Alerts)
- [ ] Cost budgets/alarms & tagging
- [ ] Runbooks & quarterly game days
