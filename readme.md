# 🌐 Rubinho Install Work

<div align="center">

![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)

**Complete development environment configurations for Linux and macOS**

[🇺🇸](#-1) • [🇧🇷](#-2)

</div>

---

## 🇺🇸

> Complete development environment configurations for **Linux** and **macOS**

This repository contains **complete development environment configurations**, including:

- 📝 Configuration files (dotfiles)
- 🎨 Themes and fonts
- ⚙️ Automated installation scripts
- 🔧 Cursor/VS Code configurations
- 🛠️ Auxiliary tools
- 🔐 Environment variables for sensitive data

---

### 🚀 Quick Start

#### 1. Clone the repository

```bash
git clone <repository-url>
cd enterprise-scripts
```

#### 2. Run the installation script

The easiest way to get started is using the main `run.sh` script:

```bash
bash run.sh
```

This will:
- Configure environment variables (`.env`)
- Ask you to select your platform (Linux or macOS)
- Run the complete installation automatically

#### 3. Manual Installation (Alternative)

If you prefer to run scripts manually:

**🐧 Linux:**

```bash
cd linux/scripts/enviroment
bash 00-install-all.sh
```

**🍎 macOS:**

```bash
cd macos/scripts/enviroment
bash 00-install-all.sh
```

**Note:** After completion, close and reopen your terminal to ensure all configurations are applied.

---

### 🔐 Environment Variables

Optional `.env` for environment-specific configuration:

```bash
cp .env.example .env
nano .env  # Fill in your configuration details
```

**Environment variables:**
- `GIT_USER_NAME` - Your Git user name
- `GIT_USER_EMAIL` - Your Git user email
- `GITHUB_TOKEN` - For private repositories
- `AWS_SSO_START_URL` - AWS SSO configuration
- Multiple AWS accounts support

See `.env.example` for complete list.

**Benefits:**
✅ No hardcoded sensitive information
✅ Easy to share with team
✅ Secure (gitignored)
✅ Works for any organization

---

### 📋 Scripts Overview

#### **00-install-all.sh** (Master Script)

Runs all installation scripts in sequence automatically.

- Prompts for Git user name and email at the start
- Executes all scripts in the correct order
- Automatically loads NVM and environment configurations
- Handles all setup phases

**Note:** After completion, close and reopen your terminal.

---

### 📝 Individual Scripts

#### **01-configure-git.sh**
Configures Git with identity and preferences.

#### **02-install-zsh.sh**
Installs and configures Zsh as the default shell.

**⚠️ After running:** Close and reopen the terminal.

#### **03-install-zinit.sh**
Installs Zinit (fast Zsh plugin manager).

#### **04-install-starship.sh**
Installs and configures the Starship prompt.

#### **05-install-node-nvm.sh**
Installs NVM (Node Version Manager) and Node.js version 22.

#### **06-install-yarn.sh**
Installs Yarn via Corepack.

#### **07-install-tools.sh**
Installs various development tools and utilities.

#### **08-install-font-jetbrains.sh**
Installs JetBrains Mono Nerd Font.

#### **09-install-cursor.sh**
Installs Cursor Editor.
- **Linux**: Downloads .deb package and installs via dpkg
- **macOS**: Installs via Homebrew Cask

#### **10-install-claude.sh**
Installs Claude Code CLI.
- Installs @anthropic-ai/claude-code via npm
- Requires Node.js/npm

#### **10-configure-terminal.sh** (Linux only)
Configures GNOME Terminal with Dracula theme.

#### **10-configure-terminal.sh** (macOS only)
Configures iTerm2 with Dracula theme.

#### **11-configure-ssh.sh**
Configures SSH for Git.
- Generates ed25519 SSH key
- Copies public key to clipboard

**👉 After running:** Add the SSH key to GitHub/GitLab.

#### **12-configure-inotify.sh** (Linux only)
Configures inotify limits for file watching.

#### **12-install-task-master.sh** (macOS only)
Installs Task Master MCP Server.

#### **13-install-task-master.sh** (Linux only)
Installs Task Master MCP Server.

#### **14-configure-cursor.sh**
Applies Cursor configurations.
- Downloads settings from remote repository
- Configures theme and preferences

#### **15-install-docker.sh** (Linux only)
Installs Docker and Docker Compose.

**⚠️ After running:** Logout/login to use Docker without sudo.

#### **15-install-docker.sh** (macOS only)
Installs Docker Desktop for macOS.

**⚠️ After running:** Make sure Docker Desktop is running.

#### **16-install-aws-vpn-client.sh**
Installs AWS VPN Client.

#### **17-install-aws-cli.sh**
Installs AWS CLI.

#### **18-configure-aws-sso.sh**
Configures AWS SSO.
- Uses `AWS_SSO_START_URL` from `.env`

#### **19-install-dotnet.sh**
Installs .NET SDK.

#### **20-install-java.sh**
Installs Java Development Kit.

#### **21-configure-github-token.sh**
Configures GitHub token for private repositories.
- Uses `GITHUB_TOKEN` from `.env`

#### **22-install-insomnia.sh**
Installs Insomnia REST Client.

#### **23-install-tableplus.sh** (Linux only)
Installs TablePlus for Linux.

#### **23-install-tableplus.sh** (macOS only)
Installs TablePlus for macOS.

---

### 📁 Repository Structure

```
enterprise-scripts/
├── .gitignore               # Protects sensitive files
├── LICENSE                  # MIT License
├── readme.md                # This file
│
├── .env                     # Your config (gitignored)
├── .env.example             # Environment config template
│
├── lib/                     # Shared library modules
│   ├── env_helper.sh
│   ├── logging.sh
│   ├── platform.sh
│   └── tool_detection.sh
│
├── linux/                   # 🐧 Linux setup
│   └── scripts/
│       └── enviroment/      # Setup scripts (00-23)
│
└── macos/                   # 🍎 macOS setup
    └── scripts/
        └── enviroment/      # Setup scripts (00-23)
```

---

### 📝 Important Notes

#### Prerequisites
- **Git** must be installed to clone the repository
- **macOS:** Homebrew will be installed automatically if it doesn't exist

#### Required Restarts
1. **After script 02:** Close and reopen the terminal
2. **After script 15 (Linux):** Logout/login to use Docker without sudo
3. **After script 15 (macOS):** Make sure Docker Desktop is running

#### Dependencies
- Scripts must be run in numerical order (01 → 02 → 03 → ...)
- Some scripts depend on others (e.g., Yarn needs Node installed)

#### Configuration Files
- Configuration files (starship.toml, user-settings.json, cursor-keyboard.json, zsh-config) are automatically downloaded from the remote repository during installation
- The scripts fetch configurations from: `https://github.com/devrubinho/rubinho-install-dev`

---

### 🛠 Maintenance

To modify scripts, update tools or version environment adjustments, just edit the corresponding files and push the changes.

---

### 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🇧🇷

> Configurações completas de ambiente de desenvolvimento para **Linux** e **macOS**

Este repositório contém **configurações completas de ambiente de desenvolvimento**, incluindo:

- 📝 Arquivos de configuração (dotfiles)
- 🎨 Temas e fontes
- ⚙️ Scripts automatizados de instalação
- 🔧 Configurações do Cursor/VS Code
- 🛠️ Ferramentas auxiliares
- 🔐 Variáveis de ambiente para dados sensíveis

---

### 🚀 Início Rápido

#### 1. Clonar o repositório

```bash
git clone <repository-url>
cd enterprise-scripts
```

#### 2. Executar o script de instalação

A forma mais fácil de começar é usar o script principal `run.sh`:

```bash
bash run.sh
```

O script irá:
- Configurar variáveis de ambiente (`.env`)
- Solicitar que você selecione sua plataforma (Linux ou macOS)
- Executar a instalação completa automaticamente

#### 3. Instalação Manual (Alternativa)

Se preferir executar os scripts manualmente:

**🐧 Linux:**

```bash
cd linux/scripts/enviroment
bash 00-install-all.sh
```

**🍎 macOS:**

```bash
cd macos/scripts/enviroment
bash 00-install-all.sh
```

**Nota:** Após a conclusão, feche e reabra o terminal para garantir que todas as configurações sejam aplicadas.

---

### 🔐 Variáveis de Ambiente

Arquivo `.env` opcional para configuração específica do ambiente:

```bash
cp .env.example .env
nano .env  # Preencha os detalhes da configuração
```

**Variáveis de ambiente:**
- `GIT_USER_NAME` - Seu nome de usuário do Git
- `GIT_USER_EMAIL` - Seu email do Git
- `GITHUB_TOKEN` - Para repositórios privados
- `AWS_SSO_START_URL` - Configuração do AWS SSO
- Suporte a múltiplas contas AWS

Veja `.env.example` para a lista completa.

**Benefícios:**
✅ Sem informações sensíveis no código
✅ Fácil de compartilhar com a equipe
✅ Seguro (ignorado pelo git)
✅ Funciona para qualquer organização

---

### 📋 Visão Geral dos Scripts

#### **00-install-all.sh** (Script Principal)

Executa todos os scripts de instalação em sequência automaticamente.

- Solicita nome e email do Git no início
- Executa todos os scripts na ordem correta
- Carrega automaticamente NVM e configurações de ambiente
- Gerencia todas as fases de configuração

**Nota:** Após a conclusão, feche e reabra o terminal.

---

### 📝 Scripts Individuais

#### **01-configure-git.sh**
Configura o Git com identidade e preferências.

#### **02-install-zsh.sh**
Instala e configura o Zsh como shell padrão.

**⚠️ Após executar:** Feche e reabra o terminal.

#### **03-install-zinit.sh**
Instala o Zinit (gerenciador rápido de plugins Zsh).

#### **04-install-starship.sh**
Instala e configura o prompt Starship.

#### **05-install-node-nvm.sh**
Instala NVM (Node Version Manager) e Node.js versão 22.

#### **06-install-yarn.sh**
Instala Yarn via Corepack.

#### **07-install-tools.sh**
Instala várias ferramentas e utilitários de desenvolvimento.

#### **08-install-font-jetbrains.sh**
Instala a fonte JetBrains Mono Nerd Font.

#### **09-install-cursor.sh**
Instala o Cursor Editor.
- **Linux**: Baixa pacote .deb e instala via dpkg
- **macOS**: Instala via Homebrew Cask

#### **10-install-claude.sh**
Instala o Claude Code CLI.
- Instala @anthropic-ai/claude-code via npm
- Requer Node.js/npm

#### **10-configure-terminal.sh** (Apenas Linux)
Configura o GNOME Terminal com tema Dracula.

#### **10-configure-terminal.sh** (Apenas macOS)
Configura o iTerm2 com tema Dracula.

#### **11-configure-ssh.sh**
Configura SSH para Git.
- Gera chave SSH ed25519
- Copia chave pública para área de transferência

**👉 Após executar:** Adicione a chave SSH ao GitHub/GitLab.

#### **12-configure-inotify.sh** (Apenas Linux)
Configura limites do inotify para monitoramento de arquivos.

#### **12-install-task-master.sh** (Apenas macOS)
Instala o servidor MCP Task Master.

#### **13-install-task-master.sh** (Apenas Linux)
Instala o servidor MCP Task Master.

#### **14-configure-cursor.sh**
Aplica configurações do Cursor.
- Baixa configurações do repositório remoto
- Configura tema e preferências

#### **15-install-docker.sh** (Apenas Linux)
Instala Docker e Docker Compose.

**⚠️ Após executar:** Faça logout/login para usar Docker sem sudo.

#### **15-install-docker.sh** (Apenas macOS)
Instala Docker Desktop para macOS.

**⚠️ Após executar:** Certifique-se de que o Docker Desktop está em execução.

#### **16-install-aws-vpn-client.sh**
Instala o cliente AWS VPN.

#### **17-install-aws-cli.sh**
Instala o AWS CLI.

#### **18-configure-aws-sso.sh**
Configura AWS SSO.
- Usa `AWS_SSO_START_URL` do `.env`

#### **19-install-dotnet.sh**
Instala o SDK .NET.

#### **20-install-java.sh**
Instala o Java Development Kit.

#### **21-configure-github-token.sh**
Configura token do GitHub para repositórios privados.
- Usa `GITHUB_TOKEN` do `.env`

#### **22-install-insomnia.sh**
Instala o cliente REST Insomnia.

#### **23-install-tableplus.sh** (Apenas Linux)
Instala TablePlus para Linux.

#### **23-install-tableplus.sh** (Apenas macOS)
Instala TablePlus para macOS.

---

### 📁 Estrutura do Repositório

```
enterprise-scripts/
├── .gitignore               # Protege arquivos sensíveis
├── LICENSE                  # Licença MIT
├── readme.md                # Este arquivo
│
├── .env                     # Sua configuração (ignorado pelo git)
├── .env.example             # Modelo de configuração
│
├── lib/                     # Módulos de biblioteca compartilhados
│   ├── env_helper.sh
│   ├── logging.sh
│   ├── platform.sh
│   └── tool_detection.sh
│
├── linux/                   # 🐧 Configuração Linux
│   └── scripts/
│       └── enviroment/      # Scripts de configuração (00-23)
│
└── macos/                   # 🍎 Configuração macOS
    └── scripts/
        └── enviroment/      # Scripts de configuração (00-23)
```

---

### 📝 Notas Importantes

#### Pré-requisitos
- **Git** deve estar instalado para clonar o repositório
- **macOS:** Homebrew será instalado automaticamente se não existir

#### Reinicializações Necessárias
1. **Após script 02:** Feche e reabra o terminal
2. **Após script 15 (Linux):** Faça logout/login para usar Docker sem sudo
3. **Após script 15 (macOS):** Certifique-se de que o Docker Desktop está em execução

#### Dependências
- Scripts devem ser executados em ordem numérica (01 → 02 → 03 → ...)
- Alguns scripts dependem de outros (ex: Yarn precisa do Node instalado)

#### Arquivos de Configuração
- Arquivos de configuração (starship.toml, user-settings.json, cursor-keyboard.json, zsh-config) são baixados automaticamente do repositório remoto durante a instalação
- Os scripts buscam configurações de: `https://github.com/devrubinho/rubinho-install-dev`

---

### 🛠 Manutenção

Para modificar scripts, atualizar ferramentas ou ajustes de versão do ambiente, basta editar os arquivos correspondentes e enviar as alterações.

---

### 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo LICENSE para detalhes.
