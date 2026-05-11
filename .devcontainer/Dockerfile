# Building the image:
#
# 1. Be sure to have C/C++test Standard and C/C++test CT distribution files (.tar.gz) in the same directory as this Dockerfile.
# 2. Be sure to have auth.json file with your OpenAI API key in the same directory as this Dockerfile:
#    {
#        "auth_mode": "apikey",
#        "OPENAI_API_KEY": "123456_OPEN_API_KEY_VALUE_123456"
#    }
# 3. If needed, customize the license server configuration in this Dockerfile (search for "ls_url", "ls_auth", "ls_user", "ls_password" variables).
# 4. Run the following command in this directory to build the image:
#    > docker build -t cpptest:demo .
# 5. Verify the image was created successfully:
#    > docker images cpptest:demo
#
# Using the image:
#
# A. Run the container directly:
#    > docker run -it --rm cpptest:demo bash
# B. Use the image with VScode Remote Containers extension by creating a '.devcontainer/devcontainer.json' file in your project with the following content:
# {
#     "image": "cpptest:demo",
#     "runArgs": [ "--rm" ],
#     "customizations": {
#         "vscode": {
#             "extensions": [
#                 "parasoft.vscode-cpptest"
#             ]
#         }
#     }
# }
# C. Use the pre-installed GitHub Actions runner:
#    Run the container:
#    > docker run --rm -it cpptest:demo bash
#    Activate / register / run GitHub Runner inside the container (following instructions from GitHub):
#    > cd actions-runner
#    > ./config.sh --url https://github.com/my/project --token MYTOKENFROMGITHUB
#    > ./run.sh
#

# baseline image
FROM debian:13

# install toolchains and utilities
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        gcc g++ make cmake git mc vim wget curl fontconfig sudo openssh-client ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# install python, node and jre
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        python3.13 python-is-python3 nodejs npm openjdk-21-jre-headless unzip && \
    rm -rf /var/lib/apt/lists/*

# configure default user
RUN groupadd parasoft && \
    useradd -d /home/parasoft -m -g parasoft -G sudo -s /bin/bash parasoft && \
    echo "parasoft:parasoft" | chpasswd

# install parasoft tools - be sure to have original cpptest distribution files (.tar.gz)!
WORKDIR /opt/parasoft
COPY parasoft_cpptest_*.tar.gz .
RUN \
    tar -xzvf parasoft_cpptest_ct-*.tar.gz && \
    tar -xzvf parasoft_cpptest_standard-*.tar.gz && \
    rm -f parasoft_cpptest_*.tar.gz

# pre-install vscode extension
WORKDIR /home/parasoft
RUN \
    if [ -f /opt/parasoft/cpptest/integration/vscode/*.vsix ] ; then \
        mkdir -p .vscode-server/extensions && \
        cp /opt/parasoft/cpptest/integration/vscode/*.vsix .vscode-server/extensions/ && \
        cd .vscode-server/extensions && \
        ext_version=$(ls *.vsix | grep -oP '\d+\.\d+\.\d+') && \
        unzip *.vsix && \
        mv extension parasoft.vscode-cpptest-$ext_version && \
        mv extension.vsixmanifest parasoft.vscode-cpptest-$ext_version/.vsixmanifest && \
        rm *.vsix && rm *.xml && \
        cd ../.. && \
        mkdir -p .vscode-server/data/Machine && \
        echo '{ "cpptest.installationLocation": "/opt/parasoft/cpptest" }' > .vscode-server/data/Machine/settings.json \
    ; else \
        echo "Skipped pre-installing Visual Studio Code extension" \
    ; fi

# pre-install GitHub self-hosted runner
WORKDIR /home/parasoft
RUN \
    mkdir actions-runner && cd actions-runner && \
    curl -o actions-runner-linux-x64-2.333.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.333.0/actions-runner-linux-x64-2.333.0.tar.gz && \
    echo "7ce6b3fd8f879797fcc252c2918a23e14a233413dc6e6ab8e0ba8768b5d54475  actions-runner-linux-x64-2.333.0.tar.gz" | shasum -a 256 -c && \
    tar xzf ./actions-runner-linux-x64-2.333.0.tar.gz && \
    ./bin/installdependencies.sh

# pre-install GitHub CLI
WORKDIR /home/parasoft
RUN \
    (type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
	&& sudo mkdir -p -m 755 /etc/apt/keyrings \
	&& out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	&& cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& sudo mkdir -p -m 755 /etc/apt/sources.list.d \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y \
    && rm -rf /var/lib/apt/lists/*

# pre-install Codex
WORKDIR /home/parasoft
RUN \
    npm i -g @openai/codex && \
    mkdir -p .codex && \
    echo '[projects."/home/parasoft"]' >> .codex/config.toml && \
    echo 'trust_level = "trusted"' >> .codex/config.toml && \
    echo '[notice.model_migrations]' >> .codex/config.toml && \
    echo '"gpt-5.3-codex" = "gpt-5.4"' >> .codex/config.toml
COPY auth.json .codex

# create configuration files in $HOME
WORKDIR /home/parasoft
RUN \
# common license server configuration
    ls_url=https://licserv.parasoft.com.pl:8443 && \
    ls_auth=false && \
    ls_user=na && \
    ls_password=na && \
# pre-configure cpptest 
    echo 'parasoft.eula.accepted=true' >> cpptestcli.properties && \
    echo 'cpptest.license.use_network=true' >> cpptestcli.properties && \
    echo 'cpptest.license.network.edition=custom_edition' >> cpptestcli.properties && \
    echo 'cpptest.license.custom_edition_features=C++test,Static Analysis,Flow Analysis,Unit Test,Coverage,Automation,DTP Publish,Desktop Command Line,AUTOSAR Rules,CWE Rules,DISA STIG Rules,HIC++ Rules,JSF Rules,MISRA Rules,MISRA C 2012 Rules,MISRA C++ 2023 Rules,OWASP Rules,Security Rules,SEI CERT C Rules,SEI CERT C++ Rules,Code Dependency Export,LLM Integration' >> cpptestcli.properties && \
    echo 'license.network.use.specified.server=true' >> cpptestcli.properties && \
    echo 'license.network.url='$ls_url >> cpptestcli.properties && \
    echo 'license.network.auth.enabled='$ls_auth >> cpptestcli.properties && \
    echo 'license.network.user='$ls_user >> cpptestcli.properties && \
    echo 'license.network.password='$ls_password >> cpptestcli.properties && \
# pre-configure cpptest-ct
    echo 'parasoft.eula.accepted=true' >> cpptestct.properties && \
    echo 'cpptestct.license.use_network=true' >> cpptestct.properties && \
    echo 'cpptestct.license.network.edition=compliance_edition' >> cpptestct.properties && \
    echo 'license.network.use.specified.server=true' >> cpptestct.properties && \
    echo 'license.network.url='$ls_url >> cpptestct.properties && \
    echo 'license.network.auth.enabled='$ls_auth >> cpptestct.properties && \
    echo 'license.network.user='$ls_user >> cpptestct.properties && \
    echo 'license.network.password='$ls_password >> cpptestct.properties

# update permissions after installing as root
RUN \
    chown -R parasoft:parasoft /opt/parasoft && \
    chown -R parasoft:parasoft /home/parasoft

# configure environment
ENV PATH="/opt/parasoft/cpptest-ct:/opt/parasoft/cpptest-ct/bin:/opt/parasoft/cpptest:/opt/parasoft/cpptest/bin:$PATH" CPPTEST_HOME="/opt/parasoft/cpptest-ct"
WORKDIR /home/parasoft
USER parasoft:parasoft
