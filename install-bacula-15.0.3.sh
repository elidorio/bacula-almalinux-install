#!/bin/bash

# Definições personalizáveis
BACULA_VERSION="15.0.3"
POSTGRES_PASS='MinhaSenha123'
BACULA_DB_PASS='MinhaSenha123'
BACKUP_DIR="/backup"
RESTORE_DIR="/backup/bacula-restores"
BACULA_EMAIL="seuusuario@seuprovedor.com.br"
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "######################################################"
echo "# Instalação Automática do Bacula ${BACULA_VERSION} + PostgreSQL 16"
echo "######################################################"

# Verifica se é AlmaLinux
if [ ! -f /etc/almalinux-release ]; then
    echo "[ERRO] Este script é compatível apenas com AlmaLinux 8."
    exit 1
fi

# Atualização inicial
dnf update -y

# Cria diretórios necessários
mkdir -p "${RESTORE_DIR}"
chmod -R 700 "${RESTORE_DIR}"
chown -R root:root "${RESTORE_DIR}"

# Desativa SELinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0 2>/dev/null || echo "SELinux já desativado."

# Para e desabilita firewalld
systemctl stop firewalld &> /dev/null
systemctl disable firewalld &> /dev/null

# Configura regras de firewall
firewall-cmd --permanent --add-service=bacula
firewall-cmd --permanent --add-service=postgresql
firewall-cmd --reload

# Instala PostgreSQL 16 via módulo DNF
dnf module enable postgresql:16 -y
dnf install -y postgresql-server postgresql-contrib

# Remove dados antigos do PostgreSQL (caso já existam)
systemctl stop postgresql &> /dev/null
rm -rf /var/lib/pgsql/data
mkdir -p /var/lib/pgsql/data
chown postgres:postgres /var/lib/pgsql/data

# Inicializa e inicia PostgreSQL
postgresql-setup --initdb --unit postgresql
systemctl enable postgresql --now
systemctl start postgresql

# Altera senha do usuário postgres
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '${POSTGRES_PASS}';"

# Ajusta pg_hba.conf
cat > /var/lib/pgsql/data/pg_hba.conf <<EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             0.0.0.0/0               trust
host    replication     all             127.0.0.1/32            ident
host    replication     all             ::1/128                 ident
EOF

# Ajusta postgresql.conf
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /var/lib/pgsql/data/postgresql.conf

# Reinicia PostgreSQL com novas configurações
systemctl restart postgresql

# Baixa Bacula usando URL direto e confiável
cd /usr/src || exit
echo "Baixando Bacula ${BACULA_VERSION}..."
wget -O bacula-${BACULA_VERSION}.tar.gz "https://netix.dl.sourceforge.net/project/bacula/bacula/${BACULA_VERSION}/bacula-${BACULA_VERSION}.tar.gz"

# Verifica integridade do arquivo baixado
tar -tvzf bacula-${BACULA_VERSION}.tar.gz > /dev/null
if [ $? -ne 0 ]; then
    echo "[ERRO] Arquivo tar.gz corrompido ou inválido!"
    exit 1
fi

# Descompacta e entra no diretório
tar -xzvf bacula-${BACULA_VERSION}.tar.gz
cd bacula-${BACULA_VERSION} || exit

# Instala dependências necessárias
dnf install -y make gcc-c++ readline-devel zlib-devel lzo-devel libacl-devel mt-st mtx postfix openssl-devel postgresql-devel perl

# Configura Bacula com PostgreSQL 16
./configure \
  --with-readline=/usr/include/readline \
  --disable-conio \
  --bindir=/usr/bin \
  --sbindir=/usr/sbin \
  --with-scriptdir=/usr/libexec/bacula/ \
  --with-working-dir=/var/spool/bacula/ \
  --with-logdir=/var/log \
  --enable-smartalloc \
  --with-postgresql \
  --with-archivedir="${BACKUP_DIR}" \
  --with-jobemail="${BACULA_EMAIL}" \
  --with-hostname="${SERVER_IP}" \
  --with-tls \
  --with-lzo \
  --with-zlib \
  --with-systemd \
  --with-openssl \
  --with-cloud \
  --with-bat

# Compila e instala
make -j$(nproc) && make install && make install-autostart

# Ajusta permissões
chown root:postgres -R /usr/libexec/bacula
chmod 770 -R /usr/libexec/bacula
chmod 770 -R /etc/bacula
chmod 770 -R "${BACKUP_DIR}"
chmod 770 /usr/sbin/dbcheck

# Instala pacote contrib necessário para dbcheck
dnf install -y postgresql-contrib

# Cria banco e usuário Bacula
cd /usr/libexec/bacula/
sudo -u postgres ./create_postgresql_database
sudo -u postgres ./make_postgresql_tables
sudo -u postgres ./grant_postgresql_privileges
sudo -u postgres psql -c "ALTER USER bacula WITH PASSWORD '${BACULA_DB_PASS}';"

# Atualiza bacula-dir.conf com a senha do usuário bacula
sed -i "s/dbpassword = \"\"/dbpassword = \"${BACULA_DB_PASS}\"/" /etc/bacula/bacula-dir.conf

# Reinicia PostgreSQL
systemctl restart postgresql

# Gerencia os serviços do Bacula
systemctl daemon-reload
systemctl enable bacula-dir bacula-sd bacula-fd --now
systemctl start bacula-dir bacula-sd bacula-fd

# Mensagem final
echo "######################################################"
echo "# Instalação concluída com sucesso!"
echo "#"
echo "# Próximos passos:"
echo "# 1. Reinicie o servidor: sudo reboot"
echo "# 2. Teste o console do Bacula: bconsole"
echo "#"
echo "# Banco de dados criado com sucesso."
echo "# Usuário Bacula configurado com a senha fornecida."
echo "######################################################"