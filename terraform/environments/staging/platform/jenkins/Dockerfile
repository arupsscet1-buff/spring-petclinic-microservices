FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive

# -----------------------------------------------------------------------------
# Install base packages
# -----------------------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y \
        ca-certificates \
        curl \
        git \
        gnupg \
        tar \
        unzip \
        wget \
        openjdk-21-jdk && \
    rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Install Apache Maven 3.9.16
# -----------------------------------------------------------------------------
RUN wget https://dlcdn.apache.org/maven/maven-3/3.9.16/binaries/apache-maven-3.9.16-bin.tar.gz -P /tmp && \
    tar -xzf /tmp/apache-maven-3.9.16-bin.tar.gz -C /opt && \
    ln -s /opt/apache-maven-3.9.16 /opt/maven && \
    rm /tmp/apache-maven-3.9.16-bin.tar.gz

ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
ENV M2_HOME=/opt/maven
ENV MAVEN_HOME=/opt/maven
ENV PATH="${M2_HOME}/bin:${PATH}"

# -----------------------------------------------------------------------------
# Install Trivy
# -----------------------------------------------------------------------------
RUN wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
        gpg --dearmor -o /usr/share/keyrings/trivy.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | \
        tee /etc/apt/sources.list.d/trivy.list > /dev/null && \
    apt-get update && \
    apt-get install -y trivy && \
    rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Install Gitleaks
# -----------------------------------------------------------------------------
ENV GITLEAKS_VERSION=8.28.0

RUN wget -O /tmp/gitleaks.tar.gz \
    https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz && \
    tar -xzf /tmp/gitleaks.tar.gz -C /usr/local/bin gitleaks && \
    chmod +x /usr/local/bin/gitleaks && \
    rm /tmp/gitleaks.tar.gz

# -----------------------------------------------------------------------------
# Install Docker CLI
# -----------------------------------------------------------------------------
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    ARCH=$(dpkg --print-architecture) && \
    CODENAME=$(. /etc/os-release && echo ${UBUNTU_CODENAME:-$VERSION_CODENAME}) && \
    echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${CODENAME} stable" \
        > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y \
        docker-ce-cli \
        docker-buildx-plugin \
        docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Install kubectl
# -----------------------------------------------------------------------------
RUN curl -LO https://dl.k8s.io/release/v1.36.0/bin/linux/amd64/kubectl && \
    install -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# -----------------------------------------------------------------------------
# Verify installations
# -----------------------------------------------------------------------------
RUN java --version && \
    mvn --version && \
    git --version && \
    docker --version && \
    trivy --version && \
    gitleaks version && \
    kubectl version --client

CMD ["/bin/bash"]