# [Choice] Ruby version (use -bullseye variants on local arm64/Apple Silicon): 3, 3.0, 2, 2.7, 2.6, 3-bullseye, 3.0-bullseye, 2-bullseye, 2.7-bullseye, 2.6-bullseye, 3-buster, 3.0-buster, 2-buster, 2.7-buster, 2.6-buster
ARG VARIANT=3.0
FROM mcr.microsoft.com/devcontainers/ruby:${VARIANT}

# Install Rails
RUN gem install rails webdrivers

# Install debug gem (rdbg) into the RVM gem path so VS Code debugger can find it
RUN gem install --install-dir /usr/local/rvm/gems/default --bindir /usr/local/rvm/gems/default/bin debug

# Default value to allow debug server to serve content over GitHub Codespace's port forwarding service
# The value is a comma-separated list of allowed domains 
ENV RAILS_DEVELOPMENT_HOSTS=".githubpreview.dev"

# [Choice] Node.js version: lts/*, 16, 14, 12, 10
ARG NODE_VERSION="lts/*"
RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"

# [Optional] Install additional OS packages (git-flow for git branching support).
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
	&& apt-get -y install --no-install-recommends git-flow \
	&& rm -rf /var/lib/apt/lists/*

# Install GitHub CLI (gh)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	| dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
	&& chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
	| tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& apt-get update \
	&& apt-get -y install --no-install-recommends gh \
	&& rm -rf /var/lib/apt/lists/*

# [Optional] Uncomment this line to install additional gems.
# RUN gem install <your-gem-names-here>


# [Optional] Uncomment this line to install global node packages.
# RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install -g <your-package-here>" 2>&1

ENV DB="sqlite3"
ENV SECRET_KEY_BASE="9f04b49f2082db69e973ef257614ff2533ab2fe07e88767c3d34241c1766288f9a371bf8660102d034e11843ab8493c43312d8a4e0bfbae08842f4f2140342e1"