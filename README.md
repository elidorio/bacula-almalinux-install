# Bacula 15.0.3 - Instalação Automática no AlmaLinux 8.10

Este repositório contém um script automático para instalar e configurar o **Bacula 15.0.3** em servidores **AlmaLinux 8.10**, utilizando **PostgreSQL 16** como backend.

## ✅ Funcionalidades

- Instalação automática do Bacula a partir do código fonte
- Configuração do PostgreSQL 16 com usuário e banco dedicados
- Criação dos diretórios de backup e restauração
- Desativa SELinux e FirewallD
- Ativa os serviços do Bacula (director, storage e file daemon)
- Pronto para uso imediato com `bconsole`

## 🛠 Requisitos

- Sistema: AlmaLinux 8.10
- Acesso root ou sudo
- Conexão com a internet
- Recomenda-se uma máquina dedicada ao Bacula

## 🔧 Como usar

1. Faça o download do script:
   ```bash
   wget https://raw.githubusercontent.com/elidorio/bacula-almalinux-install/main/install-bacula-15.0.3.sh

2. Torne-o executável:

chmod +x install-bacula-15.0.3.sh

3. Execute como root:

./install-bacula-15.0.3.sh

4. Reinicie o servidor:

reboot

5. Acesse o console do Bacula:

bconsole

## 📌 Notas Importantes
- O script desativa o SELinux permanentemente.
- Todos os serviços são habilitados na inicialização.
- As senhas padrão estão definidas no script e devem ser alteradas conforme necessário.

## 📝 Créditos
Script criado com base na experiência da comunidade e adaptado para AlmaLinux 8.10.

## 📢 Contribuição
Contribuições são bem-vindas! Abra uma issue ou pull request.
