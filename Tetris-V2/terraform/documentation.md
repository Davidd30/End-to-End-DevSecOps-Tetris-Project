Perfect doc 👌 — content-wise it’s already solid.
What you asked for is **refactoring spaces + formatting + consistency**, **without changing meaning**.

Below is the **FULL, CLEAN, UPDATED VERSION** with:

* Consistent spacing
* Clear section separation
* Uniform tables
* Cleaner headings
* Better readability for documentation **and** presentation

---

# Terraform EKS Infrastructure — Project Documentation

> **Purpose:** Complete reference for documentation and presentation
> **Project:** DevSecOps Tetris — EKS Infrastructure Provisioning

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture Diagram](#2-architecture-diagram)
3. [Project Structure](#3-project-structure)
4. [Module Reference](#4-module-reference)
5. [Count vs for_each](#5-count-vs-for_each)
6. [Security Groups](#6-security-groups)
7. [Data Flow & Dependencies](#7-data-flow--dependencies)
8. [Configuration Variables](#8-configuration-variables)
9. [How to Run](#9-how-to-run)
10. [Presentation Talking Points](#10-presentation-talking-points)

---

## 1. Project Overview

### What This Project Does

* Provisions **AWS EKS (Kubernetes)** infrastructure using **Terraform**
* Uses a **modular architecture** with explicit dependencies (`depends_on`)
* Includes:

  * VPC
  * Subnets
  * NAT Gateway
  * Route tables
  * IAM
  * Security groups
  * EKS cluster and node groups

### Key Design Decisions

| Decision           | Implementation                              |
| ------------------ | ------------------------------------------- |
| Availability zones | 3 AZs (us-east-1a, us-east-1b, us-east-1c)  |
| NAT gateways       | 1 NAT gateway (cost-optimized)              |
| Route tables       | 1 public RT, 1 private RT (shared)          |
| Subnet strategy    | Public for NAT / ALB, Private for EKS nodes |
| Terraform state    | Remote S3 backend with encryption           |

---

## 2. Architecture Diagram

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                               VPC (10.0.0.0/16)                               │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │  PUBLIC SUBNETS (1 per AZ)                                                │ │
│  │                                                                           │ │
│  │  us-east-1a: 10.0.1.0/24   us-east-1b: 10.0.2.0/24   us-east-1c: 10.0.3.0/24│ │
│  │                                                                           │ │
│  │  ┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐ │ │
│  │  │ NAT Gateway (1)  │     │   (Future ALB)   │     │                  │ │ │
│  │  │ in subnet[0]     │     │   + ALB SG       │     │                  │ │ │
│  │  └────────┬─────────┘     └────────┬─────────┘     └──────────────────┘ │ │
│  └───────────┼────────────────────────┼────────────────────────────────────┘ │
│              │                        │                                       │
│              ▼                        ▼                                       │
│       Internet Gateway           Internet Access                               │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │  PRIVATE SUBNETS (1 per AZ) — EKS Worker Nodes                            │ │
│  │                                                                           │ │
│  │  10.0.101.0/24   10.0.102.0/24   10.0.103.0/24                            │ │
│  │                                                                           │ │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐      │ │
│  │  │ Worker Node 1    │  │ Worker Node 2    │  │ Worker Node 3    │      │ │
│  │  │ Worker Nodes SG  │  │ Worker Nodes SG  │  │ Worker Nodes SG  │      │ │
│  │  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘      │ │
│  │           │                     │                     │                 │ │
│  │           └─────────────────────┴─────────────────────┘                 │ │
│  │                 NodePort 30000–32767 (inter-node traffic)                 │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Project Structure

```
terraform/
├── main.tf                    # Root orchestration and module wiring
├── variables.tf               # Root input variables
├── outputs.tf                 # Root outputs
├── terraform.tfvars           # Environment-specific values
├── .gitignore                 # Terraform & generated files
├── backend/
│   ├── main.tf                # Remote backend configuration
│   └── outputs.tf
└── modules/
    ├── vpc/
    ├── subnet/
    ├── route_table/
    ├── route_table_association/
    ├── security_group/
    ├── iam/
    └── eks/
```

---

## 4. Module Reference

### Layer 1: VPC

**Purpose:** Create a single VPC with DNS support.

| File         | Description          |
| ------------ | -------------------- |
| main.tf      | VPC resource         |
| variables.tf | CIDR and environment |
| outputs.tf   | Exports `vpc_id`     |

**Resources:** `aws_vpc`

---

### Layer 2: Subnets

**Purpose:** Create public and private subnets across AZs.

| Resource           | Iteration | Purpose                |
| ------------------ | --------- | ---------------------- |
| aws_subnet.public  | count     | Public subnets per AZ  |
| aws_subnet.private | count     | Private subnets per AZ |

**Subnet → AZ Mapping**

| Subnet           | AZ         | CIDR          |
| ---------------- | ---------- | ------------- |
| public-subnet-1  | us-east-1a | 10.0.1.0/24   |
| public-subnet-2  | us-east-1b | 10.0.2.0/24   |
| public-subnet-3  | us-east-1c | 10.0.3.0/24   |
| private-subnet-1 | us-east-1a | 10.0.101.0/24 |
| private-subnet-2 | us-east-1b | 10.0.102.0/24 |
| private-subnet-3 | us-east-1c | 10.0.103.0/24 |

---

### Layer 3: Route Tables

**Purpose:** Internet and outbound access.

| Resource                | Purpose                             |
| ----------------------- | ----------------------------------- |
| aws_internet_gateway    | Internet access for public subnets  |
| aws_eip                 | Elastic IP for NAT gateway          |
| aws_nat_gateway         | Outbound access for private subnets |
| aws_route_table.public  | 0.0.0.0/0 → IGW                     |
| aws_route_table.private | 0.0.0.0/0 → NAT                     |

---

### Layer 4: Route Table Association

| Resource                    | Iteration | Purpose                      |
| --------------------------- | --------- | ---------------------------- |
| aws_route_table_association | count     | Bind subnets to route tables |

---

### Layer 5: IAM

**Purpose:** IAM roles and permissions for EKS.

| Component         | Implementation |
| ----------------- | -------------- |
| Cluster role      | aws_iam_role   |
| Node role         | aws_iam_role   |
| Policy attachment | for_each       |

---

### Layer 5b: Security Groups

See [Security Groups](#6-security-groups).

---

### Layer 6: EKS

**Purpose:** Provision Kubernetes cluster and node groups.

| Resource            | Purpose              |
| ------------------- | -------------------- |
| aws_eks_cluster     | Control plane        |
| aws_launch_template | Node configuration   |
| aws_eks_node_group  | Managed worker nodes |

---

## 5. Count vs for_each

| Module            | Resource                    | Method   | Reason                |
| ----------------- | --------------------------- | -------- | --------------------- |
| subnet            | aws_subnet                  | count    | List-based AZ mapping |
| route association | aws_route_table_association | count    | One per subnet        |
| iam               | policy attachment           | for_each | Stable keys           |
| eks               | node groups                 | for_each | Map-driven config     |

---

## 6. Security Groups

### Worker Nodes Security Group

| Rule Type | Protocol | Ports       | Source    | Description       |
| --------- | -------- | ----------- | --------- | ----------------- |
| Ingress   | TCP      | 80          | ALB SG    | HTTP traffic      |
| Ingress   | TCP      | 30000–32767 | ALB SG    | NodePort from ALB |
| Ingress   | TCP      | 30000–32767 | Self      | Node-to-node      |
| Egress    | All      | All         | 0.0.0.0/0 | Outbound          |

**Attachment:** Launch template in EKS node groups.

---

### ALB Security Group (Future)

| Rule Type | Protocol | Ports | Source    | Description |
| --------- | -------- | ----- | --------- | ----------- |
| Ingress   | TCP      | 80    | 0.0.0.0/0 | HTTP        |
| Ingress   | TCP      | 443   | 0.0.0.0/0 | HTTPS       |
| Egress    | All      | All   | 0.0.0.0/0 | To workers  |

---

## 7. Data Flow & Dependencies

```
VPC
 └─ Subnets
     └─ Route Tables
         └─ Route Associations
             ├─ IAM
             ├─ Security Groups
             └─ EKS-
             --subnet
             --route_table_association
```

---

## 8. Configuration Variables

### terraform.tfvars

| Variable           | Value                              |
| ------------------ | ---------------------------------- |
| region             | us-east-1                          |
| vpc_cidr           | 10.0.0.0/16                        |
| availability_zones | us-east-1a, us-east-1b, us-east-1c |
| eks_cluster_name   | rina-eks-cluster                   |
| cluster_version    | 1.29                               |

---

## 9. How to Run

```bash
terraform init
terraform plan
terraform apply
terraform destroy
```

---

## 10. Presentation Talking Points

* Modular Terraform design
* Secure, private EKS worker nodes
* Cost-optimized NAT strategy
* Clean dependency graph
* Production-ready DevSecOps setup

---