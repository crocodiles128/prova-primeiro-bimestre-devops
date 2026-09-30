# Implementation Plan: API de Reservas DevOps (TechNova)

## Overview

Este documento detalha o plano de implementação completo da **API de Reservas da TechNova**, cobrindo toda a jornada do projeto — do versionamento Git até a infraestrutura provisionada na AWS com Terraform modularizado. As tarefas estão organizadas em 8 fases sequenciais e referenciadas aos requisitos do `requirements.md`.

A estratégia de commits está distribuída ao longo das fases para garantir o mínimo de **6 commits com Conventional Commits** e ao menos **uma feature branch com merge para `main`**, conforme exigido pelo RF-01.

---

## Tasks

### Fase 1 — Fundação do Projeto

- [ ] 1. Criar o repositório Git e a estrutura inicial do projeto
  - Criar repositório público no GitHub com o nome `prova-primeiro-bimestre-devops`
  - Criar o arquivo `README.md` na raiz com nome completo do aluno, RA e descrição do projeto
  - Criar o arquivo `.gitignore` excluindo: `node_modules/`, `.env`, `.terraform/`, `*.tfstate`, `*.tfstate.backup`, `*.pem`, `terraform.tfvars`
  - Criar a estrutura de pastas: `app/src/routes/`, `infra/backend/`, `infra/modules/vpc/`, `infra/modules/security-group/`, `infra/modules/ec2/`, `infra/modules/rds/`, `evidencias/`
  - Realizar o primeiro commit na branch `main`
  - **Commit sugerido:** `chore: inicializa repositório com estrutura de pastas e .gitignore`
  - _Requisitos: RF-01.1, RF-01.2, RF-01.3, RNF-01.1_

- [ ] 2. Criar feature branch e planejar o workflow Git
  - Criar a branch `feature/api-reservas` a partir de `main`
  - Registrar no `README.md` o plano de branches (feature branch → merge para main)
  - **Commit sugerido:** `docs: adiciona descrição do projeto ao README`
  - _Requisitos: RF-01.5_

---

### Fase 2 — API (Aplicação Node.js/Express)

- [ ] 3. Inicializar o projeto Node.js e instalar dependências
  - Criar `app/package.json` com `npm init` (ou manualmente)
  - Adicionar dependências de produção: `express`, `pg`
  - Definir o script `start` no `package.json` apontando para `node src/index.js`
  - _Requisitos: RF-02, RF-03_

- [ ] 4. Implementar a camada de conexão com o banco de dados (`app/src/db.js`)
  - Criar `app/src/db.js` com o pool de conexão usando o pacote `pg`
  - Ler a string de conexão da variável de ambiente `DATABASE_URL`
  - Exportar a função `query(sql, params)` para uso pelos handlers das rotas
  - Adicionar tratamento de erro de conexão com log no stderr
  - _Requisitos: RF-02.11_

- [ ] 5. Implementar o schema SQL de inicialização do banco (`app/src/db.js`)
  - Adicionar ao `db.js` a função `initDb()` que executa o `CREATE TABLE IF NOT EXISTS reservas` com os campos `id SERIAL PRIMARY KEY`, `cliente VARCHAR(255) NOT NULL`, `data VARCHAR(50) NOT NULL`, `status VARCHAR(20) NOT NULL DEFAULT 'ativa'`
  - Garantir que a função seja chamada durante a inicialização da aplicação
  - _Requisitos: RF-02.1, RF-02.11_

- [ ] 6. Implementar as rotas CRUD de reservas (`app/src/routes/reservas.js`)
  - Criar `app/src/routes/reservas.js` com o roteador Express
  - Implementar `POST /reservas`: validar `cliente` e `data` (retornar 400 se ausente), inserir no banco com `INSERT ... RETURNING *`, retornar 201
  - Implementar `GET /reservas`: buscar todas as reservas com `SELECT * FROM reservas`, retornar 200 com array
  - Implementar `GET /reservas/:id`: buscar por id, retornar 200 ou 404 com `{ "error": "Reserva não encontrada" }`
  - Implementar `PUT /reservas/:id`: atualizar campos fornecidos, retornar 200 com objeto atualizado ou 404
  - Implementar `DELETE /reservas/:id`: deletar por id, retornar 200/204 ou 404
  - Tratar erros de banco retornando 500 com mensagem genérica (não expor detalhes internos)
  - _Requisitos: RF-02.1, RF-02.2, RF-02.3, RF-02.4, RF-02.5, RF-02.6, RF-02.7, RF-02.8, RF-02.9_

- [ ] 7. Implementar o ponto de entrada da aplicação (`app/src/index.js`)
  - Criar `app/src/index.js` com configuração do Express (middleware JSON)
  - Registrar o roteador de reservas em `/reservas`
  - Implementar a rota `GET /health` que retorna 200 com `{ "status": "ok", "uptime": process.uptime() }`
  - Chamar `initDb()` antes de iniciar o servidor
  - Iniciar o servidor na porta definida por `PORT` (padrão: 3000)
  - **Commit sugerido:** `feat: implementa API Node.js/Express com CRUD completo de reservas`
  - _Requisitos: RF-02.10, RF-02.1–RF-02.9_

---

### Fase 3 — Docker (Containerização)

- [ ] 8. Criar o `Dockerfile` da API (`app/Dockerfile`)
  - Criar `app/Dockerfile` com estágio único baseado em `node:20-alpine`
  - Definir `WORKDIR /app`, copiar `package*.json`, executar `npm install --production`
  - Copiar o código-fonte (`COPY src/ ./src/`)
  - Declarar `ENV PORT=3000` e `EXPOSE 3000`
  - Definir o `CMD` para iniciar a aplicação com `node src/index.js`
  - _Requisitos: RF-03.1, RF-03.2, RF-03.4, RF-03.5_

- [ ] 9. Criar o `.dockerignore` da API (`app/.dockerignore`)
  - Criar `app/.dockerignore` excluindo: `node_modules/`, `.env`, `*.log`, `npm-debug.log*`, `.git/`
  - _Requisitos: RF-03.3_

- [ ] 10. Validar o build e a execução do container da API
  - Executar `docker build -t technova-api ./app` e confirmar que a imagem é criada sem erros
  - Executar `docker run --rm -e DATABASE_URL=... -p 3000:3000 technova-api` e confirmar que a API responde em `localhost:3000/health`
  - Salvar o output de `docker build` em `evidencias/docker-build.txt`
  - **Commit sugerido:** `feat: adiciona Dockerfile single-stage node:20-alpine`
  - _Requisitos: RF-03.1, RF-03.2, RNF-05.1_

---

### Fase 4 — Banco Local (Docker Compose)

- [ ] 11. Criar o arquivo `.env.example` com as variáveis de ambiente
  - Criar `.env.example` na raiz com as chaves sem valores sensíveis:
    - `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `DATABASE_URL`, `PORT`
  - Usar valores de exemplo descritivos (`troque_esta_senha`, `technova_db`, etc.)
  - _Requisitos: RF-04.9, RNF-01.3_

- [ ] 12. Criar o `docker-compose.yml` com os três serviços
  - Criar `docker-compose.yml` na raiz com os serviços `api`, `postgres` e `redis`
  - Serviço `postgres`: imagem `postgres:15-alpine`, volume nomeado `pg_data:/var/lib/postgresql/data`, healthcheck com `pg_isready`
  - Serviço `redis`: imagem `redis:7-alpine`, healthcheck com `redis-cli ping` (sem consumer na API)
  - Serviço `api`: build a partir de `./app`, porta `3000:3000`, `depends_on` com `condition: service_healthy` somente para `postgres`
  - Definir rede bridge customizada `technova-net` e conectar os três serviços
  - Ler variáveis de ambiente do arquivo `.env` com `env_file: .env` (sem valores hardcoded)
  - _Requisitos: RF-04.1, RF-04.2, RF-04.3, RF-04.4, RF-04.5, RF-04.6, RF-04.7, RF-04.8, RNF-01.3_

- [ ] 13. Criar o arquivo `.env` local e validar o ambiente completo
  - Criar `.env` (não versionado) com os valores reais para uso local
  - Executar `docker compose up -d --build` e confirmar que os três serviços sobem
  - Executar `docker compose ps` e salvar o output em `evidencias/compose-ps.txt`
  - Validar `curl http://localhost:3000/health` retorna 200
  - Validar `curl -X POST http://localhost:3000/reservas` com JSON válido retorna 201
  - Executar `docker compose down` e `docker compose up -d` para confirmar persistência dos dados no volume
  - **Commit sugerido:** `feat: adiciona docker-compose com api, postgres e redis`
  - _Requisitos: RF-04 (todos os critérios), RNF-04 (todos os critérios), RNF-05.1_

---

### Fase 5 — Terraform Backend (Remote State)

- [ ] 14. Criar a infraestrutura do backend remoto de estado (`infra/backend/`)
  - Criar `infra/backend/main.tf` com:
    - Recurso `aws_s3_bucket` com versionamento habilitado, encriptação server-side AES-256 e Block Public Access ativado em todas as opções
    - Recurso `aws_dynamodb_table` com partition key `LockID` do tipo `String`
  - Criar `infra/backend/variables.tf` com variáveis `bucket_name`, `table_name`, `project_name`, `environment` com `description` em todas
  - Criar `infra/backend/outputs.tf` expondo `bucket_name` e `dynamodb_table_name`
  - _Requisitos: RF-09.1, RF-09.2, RF-09.3, RNF-02.1, RNF-02.3_

- [ ] 15. Executar o `terraform apply` do backend e configurar o `providers.tf` principal
  - Executar `cd infra/backend && terraform init && terraform apply` para criar o bucket S3 e a tabela DynamoDB
  - Criar `infra/providers.tf` configurando o provider `aws` com região `us-east-1`, versão `~> 5.0`, e o backend `s3` apontando para o bucket criado com `encrypt = true`
  - Executar `aws s3 ls s3://NOME-DO-BUCKET/` e confirmar que o estado é armazenado
  - **Commit sugerido:** `feat: provisiona backend remoto S3 e DynamoDB para estado Terraform`
  - _Requisitos: RF-09.4, RF-09.5, RF-09.6, RF-09.7, RNF-01.1, RNF-02.4_

---

### Fase 6 — Módulos Terraform

- [ ] 16. Implementar o módulo VPC (`infra/modules/vpc/`)
  - Criar `infra/modules/vpc/main.tf` com:
    - Recurso `aws_vpc` com CIDR `10.0.0.0/16`, DNS support e DNS hostnames habilitados
    - Subnets públicas em `us-east-1a` (10.0.1.0/24) e `us-east-1b` (10.0.3.0/24) com `map_public_ip_on_launch = true`
    - Subnets privadas em `us-east-1a` (10.0.2.0/24) e `us-east-1b` (10.0.4.0/24)
    - Recurso `aws_internet_gateway` associado à VPC
    - Recurso `aws_route_table` pública com rota `0.0.0.0/0` → IGW, associada às subnets públicas
    - Tags `Name`, `Project`, `Environment`, `ManagedBy` em todos os recursos
  - Criar `infra/modules/vpc/variables.tf` com `vpc_cidr`, `project_name`, `environment`, `availability_zones` (com `description` em todas)
  - Criar `infra/modules/vpc/outputs.tf` expondo `vpc_id`, `public_subnet_ids`, `private_subnet_ids`
  - _Requisitos: RF-05 (todos os critérios), RNF-02.1, RNF-02.2, RNF-02.3, RNF-03.3_

- [ ] 17. Implementar o módulo Security Group (`infra/modules/security-group/`)
  - Criar `infra/modules/security-group/main.tf` com:
    - Recurso `aws_security_group` genérico que recebe regras de ingress como variável
    - Egress irrestrito (`0.0.0.0/0`) em todos os SGs
    - Tags `Name`, `Project`, `Environment`, `ManagedBy`
  - Criar `infra/modules/security-group/variables.tf` com `vpc_id`, `name`, `ingress_rules`, `project_name`, `environment` (com `description` em todas)
  - Criar `infra/modules/security-group/outputs.tf` expondo `sg_id`
  - _Requisitos: RF-06.1, RF-06.2, RF-06.3, RF-06.4, RF-06.5, RF-06.6, RNF-02.1, RNF-02.2, RNF-02.3_

- [ ] 18. Implementar o módulo EC2 (`infra/modules/ec2/`)
  - Criar `infra/modules/ec2/main.tf` com:
    - Recurso `aws_instance` do tipo `t2.micro` na subnet pública recebida como input
    - Associação do `iam_instance_profile = "LabInstanceProfile"` (sem criar IAM próprio)
    - Script `user_data` usando `templatefile()` que instala Node.js 20 + Git, clona o repositório e cria o `.env` com `DATABASE_URL` construída a partir das variáveis `db_endpoint`, `db_name`, `db_user`, `db_password`
    - Tags `Name`, `Project`, `Environment`, `ManagedBy`
  - Criar `infra/modules/ec2/variables.tf` com `subnet_id`, `security_group_id`, `instance_type`, `key_name`, `db_endpoint`, `db_name`, `db_user`, `db_password` (este último com `sensitive = true`), `project_name`, `environment` (com `description` em todas)
  - Criar `infra/modules/ec2/outputs.tf` expondo `instance_id`, `public_ip`, `private_ip`
  - _Requisitos: RF-07.1, RF-07.2, RF-07.3, RF-07.4, RF-07.5, RF-07.6, RF-07.7, RNF-02.1, RNF-02.2, RNF-02.3, RNF-03.1, RNF-03.2, RNF-03.5_

- [ ] 19. Implementar o módulo RDS (`infra/modules/rds/`)
  - Criar `infra/modules/rds/main.tf` com:
    - Recurso `aws_db_subnet_group` utilizando as subnets privadas recebidas como input
    - Recurso `aws_db_instance` com `engine = "postgres"`, `engine_version = "15"`, `instance_class = "db.t3.micro"`, `allocated_storage = 20`, `publicly_accessible = false`, `storage_encrypted = true`, `multi_az = false`, `skip_final_snapshot = true`
    - Associação do Security Group recebido como input
    - Tags `Name`, `Project`, `Environment`, `ManagedBy`
  - Criar `infra/modules/rds/variables.tf` com `subnet_ids`, `security_group_id`, `db_name`, `username`, `password` (com `sensitive = true`), `project_name`, `environment` (com `description` em todas)
  - Criar `infra/modules/rds/outputs.tf` expondo `db_endpoint`, `db_name`, `db_port`
  - **Commit sugerido:** `feat: implementa módulos Terraform vpc, security-group, ec2 e rds`
  - _Requisitos: RF-08.1–RF-08.11, RNF-02.1, RNF-02.2, RNF-02.3, RNF-03.5_

---

### Fase 7 — Composição EC2 + RDS

- [ ] 21. Criar a composição dos módulos Terraform (`infra/main.tf`, `variables.tf`, `outputs.tf`)
  - Criar `infra/variables.tf` com as variáveis raiz: `project_name`, `environment`, `db_name`, `db_username`, `db_password` (com `sensitive = true`), `availability_zones` (com `description` em todas)
  - Criar `infra/main.tf` compondo os módulos na seguinte ordem:
    - `module "vpc"` → usa o módulo `./modules/vpc`
    - `module "sg_ec2"` → usa `./modules/security-group` com regras de ingress para portas 22 e 3000 (`0.0.0.0/0`), recebe `vpc_id = module.vpc.vpc_id`
    - `module "sg_rds"` → usa `./modules/security-group` com regra de ingress porta 5432 originada do `module.sg_ec2.sg_id` (não CIDR), recebe `vpc_id = module.vpc.vpc_id`
    - `module "rds"` → recebe `subnet_ids = module.vpc.private_subnet_ids` e `security_group_id = module.sg_rds.sg_id`
    - `module "ec2"` → recebe `subnet_id = module.vpc.public_subnet_ids[0]`, `security_group_id = module.sg_ec2.sg_id`, e os outputs do módulo RDS como `db_endpoint`, `db_name`, etc.
  - Criar `infra/outputs.tf` expondo `ec2_public_ip`, `rds_endpoint` e `api_url` (formato `http://<ec2_public_ip>:3000`)
  - _Requisitos: RF-10.1–RF-10.6, RNF-02.1, RNF-02.3_

- [ ] 22. Executar `terraform validate` e `terraform fmt` em todos os módulos e na raiz
  - Executar `terraform validate` em `infra/modules/vpc/`, `infra/modules/security-group/`, `infra/modules/ec2/`, `infra/modules/rds/` e `infra/`
  - Executar `terraform fmt -recursive infra/` e confirmar que não há alterações de formatação
  - Corrigir quaisquer erros de validação ou formatação encontrados
  - _Requisitos: RF-10.7, RNF-02.5_

- [ ] 23. Criar o `terraform.tfvars` local e executar `terraform plan`
  - Criar `infra/terraform.tfvars` (não versionado — já no `.gitignore`) com os valores das variáveis: `project_name`, `environment`, `db_name`, `db_username`, `db_password`
  - Executar `cd infra && terraform init && terraform plan` com credenciais do AWS Academy Learner Lab
  - Salvar o output de `terraform plan` em `evidencias/terraform-plan.txt`
  - Confirmar que o plano não apresenta erros e lista os recursos esperados
  - _Requisitos: RF-10.8, RNF-03.3, RNF-05.1_

- [ ] 24. Executar `terraform apply` e capturar evidências da infraestrutura
  - Executar `terraform apply` e aguardar a criação de todos os recursos (VPC, SGs, EC2, RDS — pode levar 5–10 minutos)
  - Anotar os outputs: `ec2_public_ip`, `rds_endpoint`, `api_url`
  - Executar `curl http://<ec2_public_ip>:3000/health` e confirmar que a API responde na nuvem
  - Executar `aws s3 ls s3://NOME-DO-BUCKET/` e confirmar o `terraform.tfstate` no bucket
  - _Requisitos: RF-10.8, RF-09.6, RNF-03.3_

- [ ] 25. Executar `terraform destroy` e documentar o procedimento de limpeza
  - Executar `terraform destroy` para destruir todos os recursos AWS após capturar as evidências
  - Documentar no `README.md` o comando para esvaziar o bucket S3 incluindo versões de objetos antes de destruir o backend: `aws s3api delete-objects ...`
  - Confirmar que nenhum recurso ativo permanece antes de abrir o PR
  - **Commit sugerido:** `feat: adiciona composição dos módulos Terraform e outputs da infraestrutura AWS`
  - _Requisitos: RNF-05.1, RNF-05.2, RNF-05.3, RNF-05.4_

---

### Fase 8 — Documentação

- [ ] 26. Escrever o `relatorio.md` com as 4 questões dissertativas
  - Criar `relatorio.md` na raiz
  - Declarar no início qual ferramenta de IA foi utilizada
  - **Questão 1 (mínimo 10 linhas):** Descrever como as Aulas 01 a 07 foram conectadas na construção da solução, detalhando a ordem seguida e o motivo (Git → Docker → Compose → Terraform VPC → SG → EC2 → RDS → Remote State → Módulos → IA)
  - **Questão 2 (mínimo 10 linhas):** Descrever os prompts principais usados, o que a IA gerou bem, o que precisou ser corrigido, e comparar com o desenvolvimento manual (economia de tempo e onde atrapalhou)
  - **Questão 3 (mínimo 10 linhas):** Explicar a arquitetura AWS provisionada, justificar por que o RDS fica na subnet privada e a EC2 na pública, como o LabRole/LabInstanceProfile foi usado, e quais ajustes o AWS Academy Learner Lab exigiu
  - **Questão 4 (mínimo 10 linhas):** Descrever o checklist aplicado antes de `terraform apply` com código gerado por IA, como a infraestrutura foi validada, e a reflexão sobre responsabilidade no uso de IA
  - Garantir que cada questão tem respostas personalizadas e não genéricas
  - _Requisitos: RF-11 (todos os critérios)_

- [ ] 27. Atualizar o `README.md` com instruções completas de uso
  - Adicionar ao `README.md` as seções:
    - **Pré-requisitos:** Node.js 18+, Docker, Docker Compose, Terraform, AWS CLI
    - **Como rodar localmente:** `cp .env.example .env` → editar `.env` → `docker compose up -d --build`
    - **Como provisionar na AWS:** instruções de configuração do `~/.aws/credentials`, `cd infra/backend && terraform apply`, `cd infra && terraform init && terraform apply`
    - **Atualização de credenciais do Learner Lab:** procedimento para atualizar `~/.aws/credentials` quando o token expirar
    - **Como destruir os recursos:** `terraform destroy` + esvaziamento do bucket S3
  - _Requisitos: RF-01.2, RNF-03.6_

- [ ] 28. Revisão final e commit de encerramento
  - Revisar o `.gitignore` e confirmar que `.env`, `*.pem`, `*.tfstate`, `*.tfstate.backup`, `.terraform/`, `terraform.tfvars` estão todos listados
  - Confirmar que a pasta `evidencias/` contém `docker-build.txt`, `compose-ps.txt` e `terraform-plan.txt`
  - Confirmar que não há credenciais ou arquivos sensíveis no histórico Git
  - Contar os commits e confirmar o mínimo de 6 com mensagens no formato Conventional Commits
  - Realizar o merge da feature branch `feature/api-reservas` para `main` via Pull Request ou merge local
  - **Commit sugerido:** `docs: adiciona relatorio.md e atualiza README com instruções completas`
  - _Requisitos: RF-01.4, RF-01.5, RF-01.6, RNF-01.1, RNF-01.2_

---

## Resumo dos Commits Planejados

| # | Commit sugerido | Fase | Tarefa |
|---|-----------------|------|--------|
| 1 | `chore: inicializa repositório com estrutura de pastas e .gitignore` | Fase 1 | T001 |
| 2 | `docs: adiciona descrição do projeto ao README` | Fase 1 | T002 |
| 3 | `feat: implementa API Node.js/Express com CRUD completo de reservas` | Fase 2 | T007 |
| 4 | `feat: adiciona Dockerfile multi-stage com usuário não-root` | Fase 3 | T011 |
| 5 | `feat: adiciona docker-compose com api, postgres e redis com healthchecks` | Fase 4 | T014 |
| 6 | `feat: provisiona backend remoto S3 e DynamoDB para estado Terraform` | Fase 5 | T016 |
| 7 | `feat: implementa módulos Terraform vpc, security-group, ec2 e rds` | Fase 6 | T020 |
| 8 | `feat: adiciona composição dos módulos Terraform e outputs da infraestrutura AWS` | Fase 7 | T025 |
| 9 | `docs: adiciona relatorio.md e atualiza README com instruções completas` | Fase 8 | T028 |

> O projeto possui **9 commits planejados**, superando o mínimo de 6 exigido pelo RF-01.4.

---

## Notes

- Tarefas marcadas com `*` são opcionais e podem ser puladas para um MVP mais rápido
- A T008 (testes de propriedade) está fora do escopo obrigatório segundo o `requirements.md` (seção "Fora de Escopo: Testes automatizados"), mas está incluída como tarefa opcional para enriquecer o aprendizado
- A ordem das tarefas é intencional: o RDS deve ser provisionado **antes** do EC2 para que o `db_endpoint` esteja disponível para o `user_data`
- O backend Terraform (T015–T016) **deve ser criado antes** da configuração do backend S3 no `providers.tf` principal
- Credenciais temporárias do AWS Academy Learner Lab expiram em ~4 horas; se o token expirar durante o `terraform apply`, reiniciar o Lab e atualizar `~/.aws/credentials`
- Todos os recursos Terraform devem ter as tags `Name`, `Project`, `Environment` e `ManagedBy` conforme RNF-02.2

---

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["T001"] },
    { "id": 1, "tasks": ["T002"] },
    { "id": 2, "tasks": ["T003"] },
    { "id": 3, "tasks": ["T004"] },
    { "id": 4, "tasks": ["T005"] },
    { "id": 5, "tasks": ["T006", "T009"] },
    { "id": 6, "tasks": ["T007", "T010"] },
    { "id": 7, "tasks": ["T008", "T011"] },
    { "id": 8, "tasks": ["T012"] },
    { "id": 9, "tasks": ["T013"] },
    { "id": 10, "tasks": ["T014"] },
    { "id": 11, "tasks": ["T015"] },
    { "id": 12, "tasks": ["T016"] },
    { "id": 13, "tasks": ["T017", "T018"] },
    { "id": 14, "tasks": ["T019", "T020"] },
    { "id": 15, "tasks": ["T021"] },
    { "id": 16, "tasks": ["T022"] },
    { "id": 17, "tasks": ["T023"] },
    { "id": 18, "tasks": ["T024"] },
    { "id": 19, "tasks": ["T025"] },
    { "id": 20, "tasks": ["T026", "T027"] },
    { "id": 21, "tasks": ["T028"] }
  ]
}
```
