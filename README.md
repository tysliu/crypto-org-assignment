# Crypto.org

## Q1: Observer Node Setup

### Overview
- The observer node is set up using AWS / Terraform / Helm
- **Note**: I was unable to start the node but was able to complete the infrastructure code

### Implementation Details
- **Infrastructure Components**:
  - `./infra`: Terraform files for AWS infrastructure
  - `./deployment`: Dockerfile, entrypoint.sh andcrypto-node-deployment.yaml

- **Network Configuration**:
  - Both Tendermint RPC and Cosmos RPC are exposed on ports (1317/26657) as Kubernetes services
  - Blockchain data uses a persistent PVC and will survive through deployments and can be backed up easily

### Notable Features
- **Flexible Entrypoint**:
  - The entrypoint accepts multiple commands, each function can be tested separately:
    - `start`: Starts the node
    - `init`: Initializes the node
    - `quicksync-only`: Downloads and extracts the quicksync snapshot

- **Security Measures**:
  - The downloading of genesis file will also perform a checksum verification
  - Added a service monitor for monitoring with Prometheus

### Questions and Answers
**Note**: Since I was unable to start the node, I've used the public REST API.

1. **What is the amount of balance address `cro1hsr2z6lr7k2szjktzjst46rr9cfavprqas20gc` has?**
   - **Answer**: 0.60254039 CRO

2. **What is the query used to retrieve this information?**
   - **Answer**:
     ```bash
     curl https://rest.mainnet.cronos-pos.org/cosmos/bank/v1beta1/balances/cro1hsr2z6lr7k2szjktzjst46rr9cfavprqas20gc
     ```

3. **What is the block hash for `13947398` and what query can be used to retrieve the information?**
   - **Answer**:
     - **Hash**: `ZmXViDp/Aps3rjfYrNzFt75pggGLuSgIFKgmzi1JTdo=`
     - **Query**:
       ```bash
       curl -s https://rest.mainnet.cronos-pos.org/cosmos/base/tendermint/v1beta1/blocks/13947398 | jq -r '.block_id.hash'
       ```

### Further Questions: Design Choices and Trade-offs

#### Operational Design
1. **QuickSync Implementation**
   - **Choice**: Using quicksync for faster node synchronization
   - **Benefits**:
     - Rapid node deployment
     - Reduced network bandwidth usage
   - **Trade-offs**:
     - Dependency on third-party snapshot availability
     - Potential security risks from untrusted snapshots

2. **Monitoring Setup**
   - **Choice**: Prometheus integration with ServiceMonitor
   - **Benefits**:
     - Comprehensive metrics collection
     - Integration with existing monitoring stacks
   - **Trade-offs**:
     - Additional resource usage
     - Increased complexity in setup

2. **Helm Setup**
   - **Choice**: Simple YAML manifests instead of helm
   - **Benefits**:
     - Speed of implementation
   - **Trade-offs**:
     - Creates service management overhead

#### Security Improvements

##### Immediate Improvements
1. **Network Security**
   - Implement network policies to restrict pod-to-pod communication
   - Add TLS encryption for RPC endpoints
   - Configure rate limiting for API endpoints

2. **Access Control**
   - Implement RBAC for Kubernetes resources
   - Add authentication for Prometheus metrics
   - Restrict container capabilities

3. **Data Security**
   - Enable encryption at rest for PVC
   - Implement backup encryption
   - Add integrity checks for blockchain data

#### Future Enhancements
1. **Infrastructure Security**
   - Implement AWS WAF for API protection
   - Add DDoS protection
   - Set up VPC endpoints for AWS services

2. **Monitoring and Alerting**
   - Add security event logging
   - Implement anomaly detection
   - Set up automated security scanning

3. **Operational Security**
   - Implement automated backup verification
   - Add node health checks
   - Set up automated security patches


## Q2: HTTP Server

### Overview
- The proxy is setup using nginx and kubernetes
- **Note**: I don't have enough time to implement enterprise grade mtls, I will describe how I will implement it below.

### Implementation Details
- **Infrastructure Components**:
  - `./deployment`: blockchain-proxy-deployment.yaml
  - `blockchain-proxy.log`

- **Configuration**:
  - rate limiting is done using default nginx feature can be found on the configMap in blockchain-proxy-deployment.yaml.

### mTLS Implementation

**Step 1: Set up Certificate Authority (CA) infrastructure**
- Establish a private CA using AWS Certificate Manager Private CA (ACM PCA)
- Create a root CA hierarchy in ACM PCA
- Configure subordinate CAs for different environments (dev, staging, prod)
- Set appropriate validity periods and key algorithms (e.g., RSA 2048 or higher)
- Implement certificate lifecycle management policies

**Step 2: Client certificate management**
- Issue client certificates
- Use ACM PCA API to generate and sign client certificates
- Implement certificate distribution mechanisms
- Consider AWS Secrets Manager for secure certificate distribution

**Integrate with AWS Systems Manager**
- Use SSM to automate certificate distribution EKS deployments
- Create maintenance windows for certificate rotation

**Implement certificate rotation automation**
- Create Lambda functions that trigger before certificate expiration
- Set up EventBridge rules to execute certificate rotation workflows

**Step 3: Service-side mTLS configuration**
- Configure AWS services for mTLS
  - For Application Load Balancer:
    - Configure TLS listeners with server certificates
    - Enable client certificate verification
    - Set up appropriate security policies
  - For Amazon EKS:
    - Load serverside certificates into nginx containers
    - Implement service mesh with AWS App Mesh or Istio
    - Configure TLS termination and client certificate validation

