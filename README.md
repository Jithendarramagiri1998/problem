# CI/CD Pipeline with Security and Compliance on AWS

## Step 1: Set Up AWS EC2 Instance

### Launch an EC2 Instance:
1. Go to the AWS Management Console.
2. Launch an EC2 instance with the following specifications:
   - **AMI**: Amazon Linux 2
   - **Instance Type**: t2.medium (or larger, depending on workload)
   - **Storage**: 20 GB (minimum)
   - **Security Group**: Allow inbound traffic on ports 22 (SSH), 8080 (Jenkins), and 30000-32767 (Kubernetes NodePorts).
   - **Key Pair**: Create or use an existing key pair for SSH access.

### SSH into the EC2 Instance:
```bash
ssh -i <your-key-pair.pem> ec2-user@<public-ip-of-ec2>
```

### Update the System:
```bash
sudo yum update -y
```

## Step 2: Install Jenkins

### Install Java (Required for Jenkins):
```bash
sudo amazon-linux-extras install java-openjdk11 -y
```

### Install Jenkins:
```bash
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
sudo yum install jenkins -y
```

### Start and Enable Jenkins:
```bash
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

### Access Jenkins:
- Open a browser and go to: `http://<public-ip-of-ec2>:8080`
- Retrieve the initial admin password:
  ```bash
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword
  ```
- Complete the Jenkins setup wizard and install recommended plugins.

## Step 3: Install and Configure Kubernetes Tools

### Install `kubectl`:
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### Install Helm:
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Install Terraform:
```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum install terraform -y
```

### Install Docker:
```bash
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
sudo usermod -aG docker jenkins
```

## Step 4: Set Up Kubernetes Cluster

### Provision EKS Cluster Using Terraform

Create a Terraform configuration file (`main.tf`) to provision an EKS cluster.

```hcl
provider "aws" {
  region = "us-west-2"
}

resource "aws_eks_cluster" "example" {
  name     = "example-cluster"
  role_arn = aws_iam_role.example.arn

  vpc_config {
    subnet_ids = [aws_subnet.example1.id, aws_subnet.example2.id]
  }
}

resource "aws_iam_role" "example" {
  name = "example-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}
```

### Apply Terraform Configuration:
```bash
terraform init
terraform apply
```

### Configure `kubectl`:
```bash
aws eks --region <region> update-kubeconfig --name <cluster-name>

# Jenkins Pipeline Setup for Secure CI/CD
```

## Step 5: Configure Jenkins Pipeline

### 5.1 Create a Jenkins Pipeline

#### Install Required Plugins:
1. Go to **Jenkins Dashboard** → **Manage Jenkins** → **Manage Plugins**.
2. Install the following plugins:
   - **Docker Pipeline**
   - **Kubernetes CLI**
   - **SonarQube Scanner**
   - **OWASP ZAP**
   - **HashiCorp Vault**

#### Create a New Pipeline:
1. Go to **Jenkins Dashboard** → **New Item**.
2. Enter a name (e.g., `microservice-pipeline`).
3. Select **Pipeline** and click **OK**.
4. In the pipeline configuration, scroll down to the **Pipeline** section.
5. Select **Pipeline script** and paste the following `Jenkinsfile`:

```groovy
pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "my-microservice:latest"
        KUBE_CONFIG = "--kubeconfig=/home/ec2-user/.kube/config"
        VAULT_ADDR = "http://<vault-server-ip>:8200"
        VAULT_TOKEN = "<vault-token>"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/your-repo/microservice.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker build -t ${DOCKER_IMAGE} .'
                }
            }
        }

        stage('SAST with SonarQube') {
            steps {
                script {
                    sh 'sonar-scanner -Dsonar.projectKey=my-microservice -Dsonar.sources=. -Dsonar.host.url=http://<sonarqube-server-ip>:9000 -Dsonar.login=<sonarqube-token>'
                }
            }
        }

        stage('Container Scan with Trivy') {
            steps {
                script {
                    sh 'trivy image ${DOCKER_IMAGE}'
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh 'kubectl ${KUBE_CONFIG} apply -f k8s/deployment.yaml'
                }
            }
        }

        stage('DAST with OWASP ZAP') {
            steps {
                script {
                    sh 'zap-baseline.py -t http://<microservice-url>'
                }
            }
        }

        stage('Compliance Check with AWS Security Hub') {
            steps {
                script {
                    sh 'aws securityhub get-findings'
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
```

### 5.2 Explanation of the Pipeline
- **Checkout**: Pulls the code from the Git repository.
- **Build Docker Image**: Builds a Docker image for the microservice.
- **SAST with SonarQube**: Runs static application security testing using SonarQube.
- **Container Scan with Trivy**: Scans the Docker image for vulnerabilities using Trivy.
- **Deploy to Kubernetes**: Deploys the microservice to the Kubernetes cluster using `kubectl`.
- **DAST with OWASP ZAP**: Runs dynamic application security testing using OWASP ZAP.
- **Compliance Check with AWS Security Hub**: Fetches compliance findings from AWS Security Hub.


## Step 6: Configure Jenkins Pipeline (with Manifest Files)

### 5.1 Create Kubernetes Manifest Files

You need to create Kubernetes manifest files to define your microservice deployment. These files are typically written in YAML and stored in your Git repository.

#### Example Manifest Files

**Deployment Manifest (`k8s/deployment.yaml`)**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-microservice
  labels:
    app: my-microservice
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-microservice
  template:
    metadata:
      labels:
        app: my-microservice
    spec:
      containers:
      - name: my-microservice
        image: my-microservice:latest
        ports:
        - containerPort: 8080
        env:
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: my-secret
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: my-secret
              key: password
```

**Service Manifest (`k8s/service.yaml`)**:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-microservice
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30000
  selector:
    app: my-microservice
```

**Secret Manifest (`k8s/secret.yaml`)**:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
  username: <base64-encoded-username>
  password: <base64-encoded-password>
```

**To encode values in Base64**:

```bash
echo -n 'admin' | base64   # Replace 'admin' with your username
echo -n 'password' | base64   # Replace 'password' with your password
```

### 5.2 Update Jenkins Pipeline to Use Manifest Files

Modify your `Jenkinsfile` to include steps for applying the Kubernetes manifest files during the deployment stage.

#### Updated `Jenkinsfile`

```groovy
pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "my-microservice:latest"
        KUBE_CONFIG = "--kubeconfig=/home/ec2-user/.kube/config"
        VAULT_ADDR = "http://<vault-server-ip>:8200"
        VAULT_TOKEN = "<vault-token>"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/your-repo/microservice.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker build -t ${DOCKER_IMAGE} .'
                }
            }
        }

        stage('SAST with SonarQube') {
            steps {
                script {
                    sh 'sonar-scanner -Dsonar.projectKey=my-microservice -Dsonar.sources=. -Dsonar.host.url=http://<sonarqube-server-ip>:9000 -Dsonar.login=<sonarqube-token>'
                }
            }
        }

        stage('Container Scan with Trivy') {
            steps {
                script {
                    sh 'trivy image ${DOCKER_IMAGE}'
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh 'kubectl ${KUBE_CONFIG} apply -f k8s/secret.yaml'
                    sh 'kubectl ${KUBE_CONFIG} apply -f k8s/deployment.yaml'
                    sh 'kubectl ${KUBE_CONFIG} apply -f k8s/service.yaml'
                }
            }
        }

        stage('DAST with OWASP ZAP') {
            steps {
                script {
                    sh 'zap-baseline.py -t http://<microservice-url>'
                }
            }
        }

        stage('Compliance Check with AWS Security Hub') {
            steps {
                script {
                    sh 'aws securityhub get-findings'
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
```

### 5.3 Explanation of Manifest Files in the Pipeline

- **Secret Manifest**: Applied first to ensure secrets are available before the deployment.
  - Example: `kubectl apply -f k8s/secret.yaml`
- **Deployment Manifest**: Defines the microservice deployment, including the Docker image, replicas, and environment variables.
  - Example: `kubectl apply -f k8s/deployment.yaml`
- **Service Manifest**: Exposes the microservice to the network.
  - Example: `kubectl apply -f k8s/service.yaml`
- **ConfigMap Manifest (Optional)**: Stores configuration data for the microservice.
  - Example: `kubectl apply -f k8s/configmap.yaml`

## Step 7: Integrate Security and Compliance (with Manifest Files)

### 6.1 Secret Management

**Store Secrets in HashiCorp Vault**:

Use Vault to securely store sensitive data (e.g., database credentials).

```bash
vault kv put secret/my-microservice username=admin password=password
```

**Inject Secrets into Kubernetes**:

Use the Vault Agent Injector to automatically inject secrets into your Kubernetes pods.

Example annotation in the Deployment manifest:

```yaml
annotations:
  vault.hashicorp.com/agent-inject: "true"
  vault.hashicorp.com/role: "my-microservice"
  vault.hashicorp.com/agent-inject-secret-db-credentials: "secret/data/my-microservice"
```

### 6.2 Compliance Checks

**Enforce Compliance in Kubernetes**:

Use tools like Kyverno or OPA Gatekeeper to enforce policies in Kubernetes.

Example Kyverno policy to block deployments with critical vulnerabilities:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: block-critical-vulnerabilities
spec:
  rules:
  - name: block-critical-vulnerabilities
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Pods with critical vulnerabilities are not allowed."
      pattern:
        spec:
          containers:
          - name: "*"
            image: "!*:*CRITICAL"
```

**Add Compliance Check Step in Pipeline**:

```groovy
stage('Enforce Compliance') {
    steps {
        script {
            sh 'kubectl ${KUBE_CONFIG} apply -f k8s/kyverno-policy.yaml'
        }
    }
}
```

By implementing these steps, your CI/CD pipeline ensures security and compliance are enforced at every stage of the development and deployment process.



## Step 8: Integrate Security and Compliance

### 6.1 Static Application Security Testing (SAST)
#### Set Up SonarQube:
- Install SonarQube on a separate server or use a cloud-hosted version.
- Generate a token in SonarQube for Jenkins integration.

#### Configure SonarQube in Jenkins:
1. Go to **Jenkins Dashboard** → **Manage Jenkins** → **Configure System**.
2. Add **SonarQube server** details (URL and token).

#### Add SAST Step in Pipeline:
- Use the `sonar-scanner` command in the pipeline to run SAST.

### 6.2 Container Vulnerability Scanning
#### Install Trivy:
```bash
sudo yum install -y https://github.com/aquasecurity/trivy/releases/download/v0.35.0/trivy_0.35.0_Linux-64bit.rpm
```

#### Add Trivy Scan Step in Pipeline:
- Use the `trivy image` command to scan the Docker image.

### 6.3 Dynamic Application Security Testing (DAST)
#### Install OWASP ZAP:
```bash
sudo yum install -y zap
```

#### Add DAST Step in Pipeline:
- Use the `zap-baseline.py` script to run DAST.

### 6.4 Compliance Checks
#### Set Up AWS Security Hub:
1. Enable **AWS Security Hub** in your AWS account.
2. Configure it to monitor compliance standards (e.g., **CIS AWS Foundations Benchmark**).

#### Add Compliance Check Step in Pipeline:
```bash
aws securityhub get-findings
```

### 6.5 Secret Management with HashiCorp Vault
#### Set Up HashiCorp Vault:
```bash
sudo yum install -y vault
vault server -dev
```

#### Store Secrets in Vault:
```bash
vault kv put secret/my-microservice username=admin password=password
```

#### Integrate Vault with Jenkins:
- Use the **Vault plugin** in Jenkins to fetch secrets during the pipeline execution.

---

# Step 9: Reporting and Remediation

## Part 1: Reporting

The goal of reporting is to provide real-time visibility into the security and compliance status of your pipeline. This involves setting up monitoring tools, generating reports, and visualizing data.

### 7.1.1 Set Up Prometheus and Grafana

#### Install Prometheus
Prometheus is a monitoring and alerting toolkit that collects metrics from your pipeline and Kubernetes cluster.

Install Prometheus on your Jenkins server or a separate EC2 instance:

```bash
sudo yum install -y prometheus
```

Start Prometheus:

```bash
sudo systemctl start prometheus
sudo systemctl enable prometheus
```

Configure Prometheus to scrape metrics from Jenkins and Kubernetes:

Edit the Prometheus configuration file (`/etc/prometheus/prometheus.yml`):

```yaml
scrape_configs:
  - job_name: 'jenkins'
    static_configs:
      - targets: ['<jenkins-server-ip>:8080']

  - job_name: 'kubernetes'
    static_configs:
      - targets: ['<kubernetes-api-server-ip>:6443']
```

#### Install Grafana
Grafana is a visualization tool that works with Prometheus to create dashboards.

Install Grafana:

```bash
sudo yum install -y grafana
```

Start Grafana:

```bash
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
```

#### Access Grafana
Open your browser and go to `http://<grafana-server-ip>:3000`.

- Log in with the default credentials (`admin/admin`) and change the password.

#### Connect Grafana to Prometheus
In Grafana:

1. Go to **Configuration → Data Sources**.
2. Add a new data source:
   - **Name**: Prometheus
   - **URL**: `http://<prometheus-server-ip>:9090`
3. Click **Save & Test**.

#### Create Dashboards
Create dashboards in Grafana to visualize security and compliance metrics:

- Number of vulnerabilities detected by Trivy.
- Number of critical findings from SonarQube.
- Compliance status from AWS Security Hub.
- Deployment success/failure rates.

### 7.1.2 Generate Real-Time Security Reports

#### Add Reporting Steps in Jenkins Pipeline
Modify your `Jenkinsfile` to include steps for generating and exporting reports:

```groovy
stage('Generate Security Report') {
    steps {
        script {
            sh 'trivy image ${DOCKER_IMAGE} --format template --template "@contrib/html.tpl" -o trivy-report.html'
            sh 'sonar-scanner -Dsonar.projectKey=my-microservice -Dsonar.sources=. -Dsonar.host.url=http://<sonarqube-server-ip>:9000 -Dsonar.login=<sonarqube-token> -Dsonar.analysis.report=sonar-report.html'
        }
    }
}
```

#### Publish Reports
Use the **HTML Publisher Plugin** in Jenkins to publish the reports.

1. Go to **Jenkins Dashboard → Manage Jenkins → Manage Plugins**.
2. Search for **HTML Publisher Plugin** and install it.
3. Add the following step to your `Jenkinsfile`:

```groovy
post {
    always {
        publishHTML(target: [
            reportDir: '.',
            reportFiles: 'trivy-report.html,sonar-report.html',
            reportName: 'Security Reports'
        ])
    }
}
```

#### Access Reports
After the pipeline runs, you can access the reports from the Jenkins job page.

## Part 2: Remediation

The goal of remediation is to automatically fix or escalate issues detected during the pipeline execution. This involves writing scripts and integrating them into the pipeline.

### 7.2.1 Automated Remediation

#### Remediate Vulnerable Containers
If Trivy detects critical vulnerabilities in a Docker image, automatically prevent the deployment or delete the vulnerable pod.

Add the following script to your `Jenkinsfile`:

```groovy
stage('Remediate Vulnerable Containers') {
    steps {
        script {
            def trivyOutput = sh(script: 'trivy image ${DOCKER_IMAGE} --severity CRITICAL', returnStdout: true).trim()
            if (trivyOutput.contains("CRITICAL")) {
                echo "Critical vulnerabilities detected. Deleting vulnerable pod."
                sh 'kubectl ${KUBE_CONFIG} delete pod my-microservice-pod'
            } else {
                echo "No critical vulnerabilities detected."
            }
        }
    }
}
```

#### Escalate Compliance Issues
If AWS Security Hub detects compliance violations, escalate the issue by sending an alert to a Slack channel or email.

Add the following script to your `Jenkinsfile`:

```groovy
stage('Escalate Compliance Issues') {
    steps {
        script {
            def securityHubOutput = sh(script: 'aws securityhub get-findings --severity HIGH', returnStdout: true).trim()
            if (securityHubOutput.contains("HIGH")) {
                echo "High-severity compliance issues detected. Sending alert."
                sh 'curl -X POST -H "Content-type: application/json" --data "{\"text\":\"High-severity compliance issues detected!\"}" https://hooks.slack.com/services/<your-slack-webhook>'
            } else {
                echo "No high-severity compliance issues detected."
            }
        }
    }
}
```

### 7.2.2 Manual Remediation Workflow

#### Manual Approval for Critical Issues
For critical issues that cannot be automatically remediated, add a manual approval step in the pipeline.

Example:

```groovy
stage('Manual Approval') {
    steps {
        script {
            def trivyOutput = sh(script: 'trivy image ${DOCKER_IMAGE} --severity CRITICAL', returnStdout: true).trim()
            if (trivyOutput.contains("CRITICAL")) {
                input message: 'Critical vulnerabilities detected. Approve deployment?', ok: 'Deploy'
            }
        }
    }
}
```

#### Notify Teams
Use tools like Slack, PagerDuty, or email to notify teams about issues that require manual intervention.

## Summary of Step 9

### **Reporting:**
- Set up **Prometheus** and **Grafana** for real-time monitoring.
- Generate and publish **security reports** using tools like **Trivy** and **SonarQube**.

### **Remediation:**
- Automate remediation for **critical vulnerabilities** and **compliance issues**.
- Escalate issues to teams for **manual intervention** when necessary.

By implementing these steps, you’ll have a comprehensive **reporting and remediation system** integrated into your Jenkins pipeline, ensuring that **security and compliance issues** are promptly addressed.
