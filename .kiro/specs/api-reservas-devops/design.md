# Design Document

## Overview

Este documento descreve o design técnico completo da **API de Reservas da TechNova**, cobrindo todos os aspectos desde a aplicação Node.js até a infraestrutura provisionada na AWS. A solução integra as práticas aprendidas nas Aulas 01 a 07: versionamento Git, containerização com Docker, orquestração local com Docker Compose e infraestrutura como código com Terraform modularizado.

A entidade central é a **Reserva**, com os campos `id`, `cliente`, `data` e `status`. Os dados são persistidos em PostgreSQL tanto no ambiente local (via Docker Compose) quanto na nuvem (via RDS gerenciado na AWS).

A solução é projetada para dois ambientes complementares:

- **Local:** API + PostgreSQL + Redis orquestrados pelo Docker Compose, com um único comando de inicialização. O Redis é incluído como terceiro serviço para reproduzir o ambiente da Aula 02; a lógica da API não depende dele.
- **Nuvem (AWS):** API rodando em EC2 numa subnet pública, banco PostgreSQL gerenciado pelo RDS em subnets privadas, toda a rede isolada numa VPC dedicada, com estado Terraform armazenado remotamente em S3 + DynamoDB.

---

## Architecture

### Ambiente Local (Docker Compose)

```
┌─────────────────────────────────────────────────────────────────┐
│                     Docker Compose Network                       │
│                    (rede bridge: technova-net)                   │
│                                                                  │
│   ┌──────────────┐     ┌──────────────┐     ┌───────────────┐   │
│   │     api      │────▶│   postgres   │     │     redis     │   │
│   │  :3000       │     │   :5432      │     │   :6379       │   │
│   │ (Node.js)    │     │ (PG 15)      │     │ (Redis 7)     │   │
│   └──────────────┘     └──────────────┘     └───────────────┘   │
│          │                    │               (standalone,       │
│          │             ┌──────────────┐        sem consumer)     │
│          │             │  pg_data     │                          │
│          │             │  (volume     │                          │
│          │             │   nomeado)   │                          │
│          │             └──────────────┘                          │
└──────────┼──────────────────────────────────────────────────────┘
           │
      :3000 (host)
```

**Fluxo de inicialização:**

1. Docker Compose inicia `postgres` e `redis` em paralelo.
2. O serviço `postgres` executa o healthcheck com `pg_isready` a cada 10 segundos.
3. O serviço `redis` executa o healthcheck com `redis-cli ping` a cada 10 segundos (standalone, sem dependente).
4. Somente após `postgres` estar `healthy`, o serviço `api` é iniciado (`depends_on` com `condition: service_healthy` apenas para `postgres`).
5. A `api` lê as variáveis de ambiente do arquivo `.env` e conecta ao PostgreSQL pelo hostname `postgres` da rede interna. O Redis está na mesma rede mas não é consumido pela API.

### Ambiente Nuvem (AWS — us-east-1)

```
┌──────────────────────────────────────────────────────────────────────┐
│  VPC: 10.0.0.0/16  (technova-vpc)                                    │
│                                                                      │
│  ┌──────────────────────────────┐  ┌───────────────────────────────┐ │
│  │   Subnet Pública             │  │   Subnet Privada              │ │
│  │   us-east-1a: 10.0.1.0/24   │  │   us-east-1a: 10.0.2.0/24    │ │
│  │   us-east-1b: 10.0.3.0/24   │  │   us-east-1b: 10.0.4.0/24    │ │
│  │                              │  │                               │ │
│  │  ┌─────────────────────┐    │  │  ┌─────────────────────────┐  │ │
│  │  │   EC2 t2.micro       │    │  │  │  RDS PostgreSQL 15       │  │ │
│  │  │   (API Node.js)      │────┼──┼─▶│  db.t3.micro            │  │ │
│  │  │   SG: sg-api         │    │  │  │  SG: sg-rds (5432)      │  │ │
│  │  │   ports: 22, 3000    │    │  │  │  publicly_accessible=   │  │ │
│  │  └─────────────────────┘    │  │  │  false                  │  │ │
│  └──────────────────────────────┘  └───────────────────────────────┘ │
│                                                                      │
│  ┌───────────────────────────────────────────────────────────────┐   │
│  │  Internet Gateway                   Route Table Pública        │   │
│  │  0.0.0.0/0 → IGW                   (associada às públicas)    │   │
│  └───────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
         │
    Internet (usuário/curl)
```

---

## Estrutura de Pastas

```
prova-primeiro-bimestre-devops/
├── README.md                       # Nome, RA, descrição do projeto
├── .gitignore                      # node_modules, .env, .terraform, *.tfstate, *.pem
├── .env.example                    # Variáveis de ambiente sem valores sensíveis
├── app/                            # Código da API de Reservas
│   ├── src/
│   │   ├── index.js                # Ponto de entrada da aplicação
│   │   ├── routes/
│   │   │   └── reservas.js         # Rotas CRUD de reservas
│   │   └── db.js                   # Configuração e pool de conexão PostgreSQL
│   ├── package.json
│   ├── Dockerfile                  # Single-stage: node:20-alpine
│   └── .dockerignore
├── docker-compose.yml              # Orquestração local: api + postgres + redis
├── infra/
│   ├── backend/                    # Infraestrutura do remote state (criada primeiro)
│   │   ├── main.tf                 # Bucket S3 + Tabela DynamoDB
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── modules/
│   │   ├── vpc/                    # Módulo de rede (VPC, subnets, IGW, route tables)
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── security-group/         # Módulo de Security Groups (EC2 e RDS)
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── ec2/                    # Módulo da instância EC2
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── rds/                    # Módulo do banco RDS PostgreSQL
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   ├── main.tf                     # Composição dos módulos
│   ├── variables.tf                # Variáveis de entrada da infra raiz
│   ├── outputs.tf                  # Outputs: IP da EC2, endpoint do RDS, URL da API
│   └── providers.tf                # Provider AWS (us-east-1) + backend S3
├── docs/                           # Documentação adicional (opcional)
├── evidencias/
│   ├── docker-build.txt            # Output de docker build (ou screenshot)
│   ├── compose-ps.txt              # Output de docker compose ps
│   └── terraform-plan.txt          # Output de terraform plan
└── relatorio.md                    # Relatório dissertativo (4 questões)
```

---

## Components and Interfaces

### API Node.js/Express

A API expõe 6 rotas HTTP sobre o recurso `reservas`:

| Método | Rota            | Ação   | Resposta de sucesso | Resposta de erro |
|--------|-----------------|--------|---------------------|------------------|
| POST   | `/reservas`     | Create | 201 + objeto criado | 400 (campo ausente) |
| GET    | `/reservas`     | Read   | 200 + array         | —                |
| GET    | `/reservas/:id` | Read   | 200 + objeto        | 404 (não encontrado) |
| PUT    | `/reservas/:id` | Update | 200 + objeto atualizado | 404 (não encontrado) |
| DELETE | `/reservas/:id` | Delete | 200 ou 204          | 404 (não encontrado) |
| GET    | `/health`       | —      | 200 + `{status, uptime}` | —           |

**Componente `db.js`:** gerencia o pool de conexão com o PostgreSQL usando a variável de ambiente `DATABASE_URL`. Expõe uma função `query(sql, params)` utilizada pelas rotas.

**Componente `routes/reservas.js`:** implementa os handlers das rotas. Cada handler valida os campos obrigatórios, delega ao `db.js` e retorna o JSON apropriado.

**Componente `index.js`:** configura o Express, registra o roteador de reservas, inicializa a conexão com o banco e inicia o servidor na porta definida por `PORT` (padrão: 3000).

### Docker Compose

Três serviços na rede bridge `technova-net`:

| Serviço  | Imagem              | Porta | Healthcheck         | Volumes            |
|----------|---------------------|-------|---------------------|--------------------|
| api      | build: ./app        | 3000  | —                   | —                  |
| postgres | postgres:15-alpine  | 5432  | `pg_isready`        | `pg_data:/var/lib/postgresql/data` |
| redis    | redis:7-alpine      | 6379  | `redis-cli ping`    | —                  |

A `api` depende de `postgres` com `condition: service_healthy`. O Redis sobe de forma independente na mesma rede — sem consumer na API.

### Módulos Terraform

Quatro módulos locais sob `infra/modules/`:

| Módulo          | Responsabilidade                                      | Inputs principais                         | Outputs principais                          |
|-----------------|-------------------------------------------------------|-------------------------------------------|---------------------------------------------|
| `vpc`           | VPC, subnets públicas/privadas, IGW, route tables     | `vpc_cidr`, `project_name`, `environment` | `vpc_id`, `public_subnet_ids`, `private_subnet_ids` |
| `security-group`| Security Groups para EC2 (22, 3000) e RDS (5432)     | `vpc_id`, `name`, `ingress_rules`         | `sg_id`                                     |
| `ec2`           | Instância EC2 t2.micro com user_data e LabInstanceProfile | `subnet_id`, `security_group_id`, `vpc_id` | `instance_id`, `public_ip`, `private_ip`   |
| `rds`           | RDS PostgreSQL 15, DB Subnet Group, encriptação       | `subnet_ids`, `security_group_id`, `db_name`, `db_username`, `db_password` | `db_endpoint`, `db_name`, `db_port` |

---

## Diagrama dos Módulos Terraform

```mermaid
flowchart TD
    subgraph backend["infra/backend (criado primeiro)"]
        B1[main.tf]
        B2[(Bucket S3\nversionamento + encriptação)]
        B3[(DynamoDB\nLockID)]
        B1 --> B2
        B1 --> B3
    end

    subgraph infra["infra/ (projeto principal)"]
        direction TB
        PROV[providers.tf\nbackend s3 → B2 + B3]

        subgraph modules["Módulos"]
            VPC["módulo vpc\nVPC + subnets\n+ IGW + routes"]
            SGEC2["módulo security-group\nSG EC2\nportas 22, 3000"]
            SGRDS["módulo security-group\nSG RDS\nporta 5432 ← sg-ec2"]
            EC2["módulo ec2\nEC2 t2.micro\n+ LabInstanceProfile\n+ user_data"]
            RDS["módulo rds\nRDS PostgreSQL 15\ndb.t3.micro\npublicly_accessible=false"]
        end

        MAIN[main.tf\nComposição dos módulos]

        MAIN --> VPC
        MAIN --> SGEC2
        MAIN --> SGRDS
        MAIN --> EC2
        MAIN --> RDS

        VPC -->|"vpc_id"| SGEC2
        VPC -->|"vpc_id"| SGRDS
        VPC -->|"public_subnet_ids[0]"| EC2
        VPC -->|"private_subnet_ids"| RDS

        SGEC2 -->|"sg_id → sg_id do EC2"| EC2
        SGEC2 -->|"sg_id → origem porta 5432"| SGRDS
        SGRDS -->|"sg_id → sg_id do RDS"| RDS
    end

    backend -->|"S3 backend\nremote state"| PROV
```

---

## Data Models

### Entidade Reserva

**Schema SQL:**

```sql
CREATE TABLE reservas (
  id        SERIAL       PRIMARY KEY,
  cliente   VARCHAR(255) NOT NULL,
  data      VARCHAR(50)  NOT NULL,
  status    VARCHAR(20)  NOT NULL DEFAULT 'ativa'
);
```

**Representação JSON (resposta da API):**

```json
{
  "id": 1,
  "cliente": "João Silva",
  "data": "2025-06-15",
  "status": "ativa"
}
```

**Restrições de negócio:**
- `id`: gerado automaticamente pelo banco (SERIAL), nunca enviado pelo cliente na criação.
- `cliente`: string não vazia, obrigatório no POST.
- `data`: string não vazia representando data (não há validação de formato estrito no banco; a validação de presença é feita na API).
- `status`: valor inicial sempre `"ativa"` na criação; pode ser atualizado via PUT para `"cancelada"` ou outro valor válido.

**Valores de entrada válidos para POST `/reservas`:**

```json
{ "cliente": "string não vazia", "data": "string não vazia" }
```

**Operações CRUD mapeadas para SQL:**

| Operação | SQL |
|----------|-----|
| Create   | `INSERT INTO reservas (cliente, data) VALUES ($1, $2) RETURNING *` |
| Read All | `SELECT * FROM reservas` |
| Read One | `SELECT * FROM reservas WHERE id = $1` |
| Update   | `UPDATE reservas SET cliente=$1, data=$2, status=$3 WHERE id=$4 RETURNING *` |
| Delete   | `DELETE FROM reservas WHERE id = $1 RETURNING *` |

---

## Fluxo de Comunicação EC2 → RDS

### Topologia de Rede

```
Internet
   │
   ▼
[Internet Gateway]
   │
   ▼
[Route Table Pública: 0.0.0.0/0 → IGW]
   │
   ▼
[Subnet Pública: 10.0.1.0/24 (us-east-1a)]
   │
[EC2 t2.micro — sg-api]          [Subnet Privada: 10.0.2.0/24 (us-east-1a)]
   │  porta 3000 (API)            [Subnet Privada: 10.0.4.0/24 (us-east-1b)]
   │                                           │
   │           porta 5432 (PostgreSQL)         │
   └──────────────────────────────────────────▶│
                                    [RDS PostgreSQL — sg-rds]
                                    publicly_accessible = false
```

### Regras dos Security Groups

**sg-api (Security Group da EC2):**

| Direção  | Protocolo | Porta | Origem      | Motivo              |
|----------|-----------|-------|-------------|---------------------|
| Ingress  | TCP       | 22    | 0.0.0.0/0   | SSH de manutenção   |
| Ingress  | TCP       | 3000  | 0.0.0.0/0   | Acesso à API        |
| Egress   | All       | All   | 0.0.0.0/0   | Saída irrestrita    |

**sg-rds (Security Group do RDS):**

| Direção  | Protocolo | Porta | Origem      | Motivo                              |
|----------|-----------|-------|-------------|-------------------------------------|
| Ingress  | TCP       | 5432  | sg-api      | Somente a EC2 acessa o PostgreSQL   |
| Egress   | All       | All   | 0.0.0.0/0   | Saída irrestrita                    |

A origem do ingress do sg-rds referencia o **ID do sg-api** (não um CIDR), seguindo o princípio do menor privilégio (RF-06.2).

### Variáveis Injetadas via user_data na EC2

O script de `user_data` do módulo `ec2` realiza as seguintes etapas:

1. Atualiza os pacotes do sistema.
2. Instala Node.js 18 e Git.
3. Clona o repositório da API.
4. Executa `npm install`.
5. Cria um arquivo `.env` com as variáveis de ambiente injetadas pelo Terraform:

```bash
#!/bin/bash
# Variáveis injetadas pelo Terraform via templatefile()
DB_HOST="${db_endpoint}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASS="${db_password}"
DB_PORT="5432"

# Escreve o .env da aplicação
cat > /home/ec2-user/app/.env <<EOF
DATABASE_URL=postgresql://$DB_USER:$DB_PASS@$DB_HOST:$DB_PORT/$DB_NAME
PORT=3000
EOF
```

> **Nota de laboratório:** Em ambiente de produção, as credenciais do banco seriam gerenciadas via AWS Secrets Manager. Para o AWS Academy Learner Lab, a injeção direta via `user_data` é aceita, mas a senha deve ser tratada como `sensitive = true` no Terraform e nunca versionada.

---

## Estratégia de Variáveis de Ambiente

### Local (Docker Compose)

O arquivo `.env` (não versionado, listado no `.gitignore`) contém os valores reais:

```env
POSTGRES_DB=technova_db
POSTGRES_USER=technova_user
POSTGRES_PASSWORD=senha_local_segura
DATABASE_URL=postgresql://technova_user:senha_local_segura@postgres:5432/technova_db
PORT=3000
```

O arquivo `.env.example` (versionado) documenta as chaves sem valores sensíveis:

```env
POSTGRES_DB=technova_db
POSTGRES_USER=technova_user
POSTGRES_PASSWORD=troque_esta_senha
DATABASE_URL=postgresql://technova_user:troque_esta_senha@postgres:5432/technova_db
PORT=3000
```

O `docker-compose.yml` usa interpolação `${VAR}` e nunca contém valores hardcoded.

### Docker (Dockerfile)

O `Dockerfile` usa `node:20-alpine` em estágio único, declara `ENV PORT=3000` e `EXPOSE 3000` como documentação. Os valores reais em runtime são fornecidos pelo Compose via `environment:` ou `env_file:`, sobrescrevendo os padrões do Dockerfile.

### Terraform

| Camada                | Arquivo               | Conteúdo                                      |
|-----------------------|-----------------------|-----------------------------------------------|
| Declaração de variáveis | `variables.tf`      | Tipo, descrição, `sensitive = true` para senhas |
| Valores de desenvolvimento | `terraform.tfvars` | Valores reais — **não versionado** (listado no `.gitignore`) |
| Outputs               | `outputs.tf`          | Valores de saída (IPs, endpoints, URLs)       |

Variáveis marcadas como `sensitive = true`: `db_password`.

### EC2 user_data

Para o laboratório, as credenciais do RDS são passadas do `outputs` do módulo RDS para o `user_data` do módulo EC2 via `templatefile()`. O endpoint e o nome do banco chegam como `outputs` do módulo RDS e são referenciados em `main.tf` raiz antes de serem repassados ao módulo EC2.

---

## Error Handling

### Erros da API

| Situação                             | Status HTTP | Resposta JSON                              |
|--------------------------------------|-------------|---------------------------------------------|
| Campo `cliente` ou `data` ausente    | 400         | `{ "error": "Campo 'cliente' é obrigatório" }` |
| Reserva não encontrada por `id`      | 404         | `{ "error": "Reserva não encontrada" }`     |
| Erro interno de banco de dados       | 500         | `{ "error": "Erro interno do servidor" }`   |

A API nunca expõe detalhes internos (mensagens do PostgreSQL, stack traces) em resposta à requisição — erros são logados no stderr do container e retornados ao cliente de forma genérica.

### Erros do Docker Compose

| Situação                                | Comportamento esperado                        |
|-----------------------------------------|-----------------------------------------------|
| Arquivo `.env` ausente                  | Compose falha com erro de variável indefinida |
| PostgreSQL não fica healthy em 30s      | Serviço `api` não sobe (depends_on bloqueia)  |

### Erros do Terraform

| Situação                                    | Ação recomendada                              |
|---------------------------------------------|-----------------------------------------------|
| `ExpiredTokenException`                     | Reiniciar o Learner Lab e atualizar `~/.aws/credentials` |
| Bucket S3 do backend não existe             | Criar o backend primeiro (`cd infra/backend && terraform apply`) |
| Erro de lock no DynamoDB                    | Verificar se há outro `apply` em execução; usar `terraform force-unlock` se necessário |
| RDS demorando para provisionar              | Aguardar 5-10 minutos; o RDS leva mais tempo que EC2 |

---

## Testing Strategy

A validação do projeto é feita exclusivamente por execução prática — não há testes automatizados (Jest, Fast-Check, Supertest). As verificações são realizadas com comandos `curl` e ferramentas CLI.

### Validação da API (Docker Compose)

| Comando | O que verifica |
|---------|----------------|
| `docker compose up -d --build` | Todos os serviços sobem sem erros |
| `docker compose ps` | 3 serviços com status `healthy` ou `running` |
| `curl http://localhost:3000/health` | API responde HTTP 200 |
| `curl -X POST http://localhost:3000/reservas -H "Content-Type: application/json" -d '{"cliente":"João","data":"2025-06-15"}'` | Reserva criada, retorna HTTP 201 |
| `curl http://localhost:3000/reservas` | Lista todas as reservas |
| `curl http://localhost:3000/reservas/1` | Retorna reserva específica |
| `curl -X PUT http://localhost:3000/reservas/1 -d '{"status":"cancelada"}'` | Atualiza reserva |
| `curl -X DELETE http://localhost:3000/reservas/1` | Remove reserva |
| `docker compose down && docker compose up -d` | Dados persistem no volume após reinício |

### Validação da Infraestrutura Terraform

| Tipo | Comando | O que verifica |
|------|---------|----------------|
| Sintaxe | `terraform validate` | Módulos sem erros de configuração |
| Plano | `terraform plan` | Recursos a criar sem erros |
| Integração | `curl http://<IP>:3000/health` | API acessível na EC2 após `apply` |
| Integração | `aws s3 ls s3://BUCKET/` | State file armazenado no S3 |
