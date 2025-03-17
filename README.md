> ⚠️ **WORK IN PROGRESS**: This repository is under active development. The architecture, configurations, and documentation are subject to change. Use with caution in production environments. See TODO list in this readme.

# E2E Encrypted Database Operations: Acra + AWS Nitro enclave

> 🚨 Did you know?
>While managed database services (RDS, CloudSQL, Aurora) offer encryption at rest, this only protects your data when it's stored on disk. Your data is still exposed in memory and decrypted at the database layer. This means your sensitive data could be vulnerable to memory dumps, compromised database users, or privileged access misuse.
> This is where Acra comes in: true end-to-end encryption for your sensitive data, ensuring it remains encrypted until it reaches your application. By running Acra inside AWS Nitro Enclaves (that is the point of this repo) and integrating with AWS KMS, we create an unprecedented security fortress. Your encryption keys are protected by hardware-level isolation, your data is encrypted at the application layer, and the entire process is attested and auditable. It's one of the most secure ways to protect sensitive data today.

## TODO list

- [ ] Ensure Reproducible flow, and example of verifiable remote attestation.
- [ ] Implement MPC (or some sort of decentrilzed KMS) for acra's master key?
- [ ] High availability setup fo the acra server; multi regional etc.
- [ ] Consider [enveloppe encryption](https://edgebit.io/enclaver/docs/0.x/guide-app/#envelope-encryption)?
- [ ] Move the postgres instance elsewhere (e.g, managed instance on AWS or GCP)
- [ ] Deploy all of the setup using IaC
- [ ] Ensure TLS everywhere
- [ ] Achitecture Diagram
- [ ] performance benchmarks
- [ ] Zero-Trust Architecture? (no implicit trust etc)

## Benefits & Motivations

### 🎯 Primary Motivation: Preventing Data Leakage
The primary goal of this architecture is to prevent sensitive data leakage (PII, financial data, health records, etc.) while maintaining practical usability in production environments. While emerging technologies like Multi-Party Computation (MPC) and Fully Homomorphic Encryption (FHE) show promise, they aren't yet production-ready or scalable for most real-world applications. This architecture provides a pragmatic alternative that's:

- **Production-Ready**: Built on battle-tested technologies (AWS Nitro, Acra, KMS/HSM)
- **Scalable**: Capable of handling production workloads with minimal performance overhead
- **Cost-Effective**: Significantly lower computational overhead compared to FHE
- **Immediately Deployable**: No need to wait for emerging technologies to mature

### 🔐 Enhanced Key Protection
- **Hardware-Level Security**: Acra's master key is protected by both AWS KMS and Nitro Enclave's hardware isolation
- **Memory Encryption**: All encryption operations occur in encrypted memory that's inaccessible to the host EC2 instance
- **Zero Key Exposure**: Cryptographic keys never leave the secure enclave boundary in plaintext form

### 🎯 Practical Privacy-Preserving Solution
- **Ready Alternative**: While MPC and FHE evolve toward production readiness, this solution offers immediate privacy protection
- **Balanced Approach**: Combines strong security guarantees with practical performance requirements
- **Real-World Tested**: Successfully deployed in regulated industries handling sensitive data
- **Future-Proof**: Architecture can integrate emerging technologies as they mature

### 🛡️ Attack Surface Reduction
- **Minimal Trust Boundary**: Even if the host EC2 instance is compromised, the attacker cannot access the encryption keys or the data processing operations
- **Isolated Execution**: The Acra Server operates in complete isolation from other processes and the host OS
- **No Persistent Storage**: Enclaves are stateless and leave no data trail on the host system

### 📊 Data Security at Scale
- **Secure Search Operations**: Enables searching encrypted data without decryption
- **High Performance**: Direct hardware access ensures minimal performance overhead for cryptographic operations (dedicated CPU and memory resources, No hypervisor overhead for cryptographic operations)
- **Production-Grade**: Proven in high-throughput, low-latency environments

### ✅ Compliance & Audit
- **Attestation Proof**: Provides cryptographic evidence of the exact code running in the enclave
- **Audit Trail**: All key operations are logged in AWS CloudTrail
- **Compliance Ready**: Helps meet GDPR, HIPAA, SOC2 type2, and other regulatory requirements for data protection

## Architecture Components

### 1. AWS Nitro Enclaves
Isolated compute environments providing enhanced security beyond standard EC2 instances.

**Key Benefits:**

- 🔒 Hardware-level isolation from parent EC2 instance
- 🛡️ Minimal attack surface with no persistent storage or interactive access
- 🔐 Encrypted memory with inaccessible encryption keys
- ✅ Cryptographic attestation capabilities

### 2. Enclaver Integration
[Enclaver](https://edgebit.io/enclaver/docs/0.x/guide-app/) is a tool for streamlined application deployment in AWS Nitro Enclaves.

### 3. AWS KMS Integration
AWS KMS handles Acra's master key encryption for enhanced key management security.

**Advantages:**

- Centralized key management system
- Automatic key rotation capabilities
- Fine-grained access control
- Comprehensive CloudTrail audit logging

### 4. Basic Pyhton app + Postgres
As a POC, we will use this basic demo [python + postgres app](https://github.com/cossacklabs/acra-engineering-demo/tree/master/python-searchable)

## Security Workflow

1. EC2 instance initiates Nitro Enclave via Enclaver
2. Enclave boots and executes Acra server setup
3. Authentication with KMS using EC2 instance's IAM role
4. Secure master key decryption and passage to Acra server
5. Acra server initialization with decrypted master key
6. Client applications connect to Acra (that acts as a database proxy) for encrypted data operations

## Security Layers

### Authentication & Authorization

- KMS authorization via IAM roles
- Enclave attestation for identity verification
- Acra's built-in client authentication mechanisms

### Data Protection Features

- Transparent encryption/decryption
- Searchable encryption capabilities
- Poison record detection

### EC2 Instance Security

- Hardened instance configuration
- Restricted IAM roles
- Minimal required permissions
- Configured security groups and ACLs

## Setup Requirements

- AWS Account with EC2 and KMS access
- IAM roles and policies configuration
- Enclaver installation
- Acra server source / package / Dockerfile / Docker image
- A basic [python + postgres app](https://github.com/cossacklabs/acra-engineering-demo/tree/master/python-searchable)

## ⚠️ Important: Reproducible Builds and Remote Attestation

Remote attestation is only meaningful when combined with reproducible builds. Here's why:

- **Attestation Reality**: Remote attestations verify the binary artifacts (EIF files) running in secure enclaves, not the source code
- **Human Verification**: While humans can review source code, they cannot directly review binaries
- **Build Process Critical**: The build process is the crucial link between source code and binaries
- **Verification Chain**: Without reproducible builds, it's impossible to independently verify which source code produced a given binary

Build process should ensures byte-for-byte identical artifacts across different builds, and Verifiable build outputs (EIF hash).

AWS Nitro Attestations provide signed messages containing:

- PCR0: Enclave Image File (EIF) hash
- PCR1: Linux kernel and initial RAM data hash
- PCR2: User applications hash
- PCR3: IAM role hash of parent EC2 instance
- Certificate chain validating the enclave's identity

## Security Considerations

### Potential Vulnerabilities
Classic Infra/IT secruity best practices should be but in place for a comprehensive setup.

1. **EC2 Instance Compromise**
   - Risk: While the enclave protects data and keys, a compromised EC2 host could:
     - Interfere with enclave I/O communication
     - Attempt resource-based denial of service
     - Monitor communication patterns
   - Mitigation: 
     - End-to-end encrypted communication channels
     - EC2 host hardening (security groups, NACLs, IMDSv2)
     - Host-based IDS/IPS
     - Regular security patching
     - AWS GuardDuty enabled

2. **KMS Key Exposure**
   - Risk: Compromise of keys used to encrypt Acra master key
   - Mitigation: 
     - Strict IAM policies with least privilege
     - Mandatory key rotation schedule
     - CloudTrail logging and monitoring
     - Multi-Region KMS for resilience
     - AWS CloudWatch alerts on key usage

3. **Side-Channel Attacks**
   - Risk: Memory timing attacks and resource usage analysis
   - Mitigation: 
     - Regular security patches for known vulnerabilities
     - Resource usage monitoring and anomaly detection
     - Implementing constant-time operations where possible
     - Physical hardware isolation (dedicated hosts)

4. **Application-Level Vulnerabilities**
   - Risk: Security gaps in application integration
   - Mitigation:
     - Secure coding practices (OWASP guidelines)
     - Regular penetration testing
     - Automated security scanning
     - Proper Acra configuration validation
     - Input/output validation at enclave boundaries

5. **Network-Level Attacks**
   - Risk: Network-based threats and MitM attempts
   - Mitigation:
     - VPC isolation
     - TLS 1.3 enforcement
     - Network flow logs
     - AWS Network Firewall
     - Regular network security assessments

## Getting Started
TODO

## Monitoring and Maintenance
Should be put in place:

- Regular security updates
- Continuous monitoring of:
  - EC2 instance health
  - Enclave operations
  - KMS key usage
  - Acra server logs
  - Application metrics

## Best Practices
Should be put in place:

1. Follow the principle of least privilege for IAM roles
2. Implement comprehensive logging and monitoring
3. Regularly rotate encryption keys
4. Maintain up-to-date security patches
5. Conduct regular security audits
6. Document all configuration changes


## Contributing

- Feel free to open PRs and GH Issues.

---
**Note**: This implementation focuses on security through reproducible builds and verifiable remote attestation. For questions or concerns about the build process, please open an issue in the repository.