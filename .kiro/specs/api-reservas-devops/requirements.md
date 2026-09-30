# Requirements Document

## Introduction

Este documento especifica os requisitos do projeto **Prova do Primeiro Bimestre — DevOps UniFAAT**, que consiste na entrega completa da **API de Reservas da TechNova**: desde o versionamento Git até a infraestrutura provisionada na AWS com Terraform modular. O projeto demonstra a jornada completa das Aulas 01 a 07, cobrindo Git, Docker, Docker Compose, Terraform (IAM, VPC, EC2, RDS, Remote State, Modules) e IA como copiloto.

O sistema gerencia reservas com os campos `id`, `cliente`, `data` e `status`, persistindo os dados em PostgreSQL tanto no ambiente local (Docker Compose) quanto na nuvem (RDS na AWS).

---

## Glossary

- **API**: Aplicação Node.js/Express que expõe as rotas HTTP da API de Reservas.
- **Banco_de_Dados**: Instância PostgreSQL responsável pela persistência das reservas.
- **Redis**: Serviço Redis incluído no Docker Compose para reproduzir o ambiente da Aula 02. Não é utilizado pela lógica da API — está presente apenas como terceiro serviço do Compose.
- **Compose**: Orquestrador local (Docker Compose) que sobe API + Banco_de_Dados + Redis.
- **Terraform**: Ferramenta de Infraestrutura como Código usada para provisionar recursos na AWS.
- **Modulo_VPC**: Módulo Terraform responsável por criar VPC, subnets, Internet Gateway e Route Tables.
- **Modulo_SG**: Módulo Terraform responsável por criar Security Groups para EC2 e RDS.
- **Modulo_EC2**: Módulo Terraform responsável por provisionar a instância EC2 que hospeda a API.
- **Modulo_RDS**: Módulo Terraform responsável por provisionar o banco PostgreSQL gerenciado na AWS.
- **Backend_Remoto**: Configuração de estado remoto do Terraform usando S3 e DynamoDB.
- **LabInstanceProfile**: Instance Profile pré-existente no AWS Academy Learner Lab, usado em substituição à criação manual de IAM roles.
- **LabRole**: IAM Role pré-existente no AWS Academy Learner Lab com permissões de execução.
- **Reserva**: Entidade central do sistema, com campos `id` (gerado automaticamente), `cliente` (string, obrigatório), `data` (string ISO 8601, obrigatório) e `status` (enum: `ativa`, `cancelada`).
- **Conventional_Commits**: Padrão de mensagens de commit (`feat:`, `docs:`, `fix:`, `chore:`).

---

## Escopo

O projeto inclui:

- Repositório Git público com histórico limpo e workflow de branches
- API de Reservas em Node.js/Express com CRUD completo persistido em PostgreSQL
- Dockerfile funcional da API
- Ambiente local com Docker Compose (API + PostgreSQL + Redis)
- Infraestrutura AWS modular com Terraform (VPC, Security Groups, EC2, RDS)
- Backend remoto de estado Terraform (S3 + DynamoDB)
- Composição entre módulos Terraform (output de um alimenta input de outro)
- Relatório dissertativo documentando o processo com uso de IA

## Fora de Escopo

- Autenticação e autorização de usuários (JWT, OAuth)
- Pipeline de CI/CD automatizado (GitHub Actions, Jenkins)
- Monitoramento e observabilidade (CloudWatch Alarms, Prometheus, Grafana)
- Load Balancer ou Auto Scaling Group
- Domínio customizado ou certificado SSL/TLS
- Ambientes múltiplos de Terraform (dev/staging/prod) — apenas um ambiente é obrigatório
- Criação de IAM Users, Groups ou Roles próprios no AWS Academy Learner Lab
- Testes automatizados (unitários, integração, e2e) — a validação é feita por execução prática com `curl` e `docker compose ps`
- Otimização de imagem Docker com multi-stage build
- Integração da API com Redis (o Redis é incluído apenas como serviço de demonstração no Compose)

---

## Requirements

### RF-01: Versionamento Git com Workflow Estruturado

**User Story:** Como avaliador, quero ver um histórico Git limpo com mínimo de 6 commits e uso de feature branch, para que eu possa verificar que o aluno domina o workflow Git aprendido na Aula 01.

#### Critérios de Aceite

1. THE Repositório SHALL ser público no GitHub com o nome `prova-primeiro-bimestre-devops`.
2. THE Repositório SHALL conter um `README.md` na raiz com nome completo do aluno, RA e descrição do projeto.
3. THE Repositório SHALL conter um `.gitignore` que exclua `node_modules/`, `.env`, `.terraform/`, `*.tfstate`, `*.tfstate.backup` e `*.pem`.
4. WHEN o histórico Git for consultado via `git log`, THE Repositório SHALL exibir no mínimo 6 commits com mensagens no formato Conventional Commits (`feat:`, `docs:`, `fix:`, `chore:`).
5. WHEN o fluxo de desenvolvimento for auditado, THE Repositório SHALL evidenciar uso de ao menos uma feature branch com merge para `main` (branch criada, commits realizados e merge concluído).
6. IF um arquivo sensível (`.env`, `*.tfstate`, `*.pem`, `.terraform/`) for incluído em um commit, THEN THE Repositório SHALL ser considerado não conforme neste requisito.

---

### RF-02: API de Reservas — CRUD Completo com Persistência

**User Story:** Como desenvolvedor da TechNova, quero uma API REST com CRUD completo de reservas persistidas em PostgreSQL, para que o ambiente de produção tenha dados duráveis e não dependa de estado em memória.

#### Critérios de Aceite

1. WHEN uma requisição `POST /reservas` for recebida com corpo JSON contendo `cliente` e `data`, THE API SHALL criar uma nova reserva no Banco_de_Dados com `id` gerado automaticamente e `status` inicial `"ativa"`, retornando HTTP 201 com o objeto criado.
2. IF uma requisição `POST /reservas` for recebida sem o campo `cliente` ou sem o campo `data`, THEN THE API SHALL retornar HTTP 400 com mensagem de erro descritiva indicando qual campo está ausente.
3. WHEN uma requisição `GET /reservas` for recebida, THE API SHALL retornar HTTP 200 com array JSON contendo todas as reservas armazenadas no Banco_de_Dados.
4. WHEN uma requisição `GET /reservas/:id` for recebida com um `id` existente, THE API SHALL retornar HTTP 200 com o objeto da reserva correspondente.
5. IF uma requisição `GET /reservas/:id` for recebida com um `id` inexistente, THEN THE API SHALL retornar HTTP 404 com mensagem de erro.
6. WHEN uma requisição `PUT /reservas/:id` for recebida com `id` existente e corpo JSON válido, THE API SHALL atualizar os campos fornecidos no Banco_de_Dados e retornar HTTP 200 com o objeto atualizado.
7. IF uma requisição `PUT /reservas/:id` for recebida com `id` inexistente, THEN THE API SHALL retornar HTTP 404 com mensagem de erro.
8. WHEN uma requisição `DELETE /reservas/:id` for recebida com `id` existente, THE API SHALL remover a reserva do Banco_de_Dados e retornar HTTP 200 ou HTTP 204.
9. IF uma requisição `DELETE /reservas/:id` for recebida com `id` inexistente, THEN THE API SHALL retornar HTTP 404 com mensagem de erro.
10. WHEN uma requisição `GET /health` for recebida, THE API SHALL retornar HTTP 200 com JSON indicando o status da aplicação e o uptime do processo.
11. THE API SHALL persistir todas as reservas no Banco_de_Dados PostgreSQL e não utilizar armazenamento em memória como fonte de verdade.

---

### RF-03: Containerização da API com Docker

**User Story:** Como engenheiro de plataforma, quero que a API seja containerizada com Dockerfile funcional, para que possa ser executada de forma reproduzível em qualquer ambiente.

#### Critérios de Aceite

1. THE API SHALL possuir um `Dockerfile` válido na pasta `app/` que permita construir a imagem com `docker build`.
2. WHEN o container for iniciado com `docker run`, THE API SHALL responder corretamente na porta 3000.
3. THE Dockerfile SHALL copiar apenas os arquivos necessários para a imagem, excluindo `node_modules/`, `.env` e arquivos de log via `.dockerignore`.
4. THE Dockerfile SHALL usar a imagem base `node:20-alpine` em estágio único.
5. THE Dockerfile SHALL declarar explicitamente a variável de ambiente `PORT` e usar `EXPOSE` para documentar a porta da aplicação.

---

### RF-04: Ambiente Local com Docker Compose

**User Story:** Como desenvolvedor, quero um ambiente local que suba com um único comando (`docker compose up`), para que eu possa desenvolver e testar a API de forma isolada sem depender da AWS.

#### Critérios de Aceite

1. WHEN o comando `docker compose up -d` for executado na raiz do repositório, THE Compose SHALL iniciar três serviços: `api`, `postgres` e `redis`.
2. THE Compose SHALL configurar o serviço `postgres` com a imagem `postgres:15-alpine` e um volume nomeado para garantir persistência dos dados entre reinicializações.
3. THE Compose SHALL configurar o serviço `redis` com a imagem `redis:7-alpine`. O serviço Redis é incluído para reproduzir o ambiente da Aula 02 e não é consumido pela lógica da API.
4. THE Compose SHALL definir uma rede bridge customizada e conectar os três serviços a ela.
5. THE Compose SHALL configurar healthcheck no serviço `postgres` usando `pg_isready`.
6. THE Compose SHALL configurar healthcheck no serviço `redis` usando `redis-cli ping`.
7. WHEN o serviço `api` for declarado no Compose, THE Compose SHALL usar `depends_on` com condição `service_healthy` somente para `postgres`, garantindo que a API só inicie após o banco estar saudável.
8. THE Compose SHALL ler todas as variáveis de ambiente de um arquivo `.env` e não conter valores sensíveis (senhas, credenciais) hardcoded no `docker-compose.yml`.
9. THE Repositório SHALL conter um arquivo `.env.example` versionado com os nomes das variáveis e valores de exemplo não sensíveis.
10. IF o arquivo `.env` não existir na raiz, THEN THE Compose SHALL falhar com mensagem clara indicando variáveis ausentes.
11. WHILE o Compose estiver em execução, THE API SHALL conectar ao Banco_de_Dados usando o hostname do serviço `postgres` definido na rede interna do Compose.

---

### RF-05: Infraestrutura AWS — Módulo VPC

**User Story:** Como engenheiro de plataforma, quero um módulo Terraform reutilizável para criar a rede AWS, para que a infraestrutura de rede seja isolada, versionada e reproduzível.

#### Critérios de Aceite

1. WHEN o Modulo_VPC for invocado, THE Modulo_VPC SHALL criar uma VPC com CIDR `10.0.0.0/16` com DNS support e DNS hostnames habilitados.
2. THE Modulo_VPC SHALL criar ao menos uma subnet pública em cada uma das duas Availability Zones configuradas (`us-east-1a` e `us-east-1b`).
3. THE Modulo_VPC SHALL criar ao menos uma subnet privada em cada uma das duas Availability Zones configuradas.
4. THE Modulo_VPC SHALL criar e associar um Internet Gateway à VPC.
5. THE Modulo_VPC SHALL criar uma Route Table pública com rota `0.0.0.0/0` apontando para o Internet Gateway e associá-la às subnets públicas.
6. THE Modulo_VPC SHALL expor os outputs `vpc_id`, `public_subnet_ids` e `private_subnet_ids` para consumo por outros módulos.
7. THE Modulo_VPC SHALL aplicar tags `Name`, `Project`, `Environment` e `ManagedBy` em todos os recursos criados.

---

### RF-06: Infraestrutura AWS — Módulo Security Group

**User Story:** Como engenheiro de plataforma, quero Security Groups configurados com o princípio do menor privilégio, para que o tráfego de rede entre os componentes seja restrito apenas ao necessário.

#### Critérios de Aceite

1. WHEN o Modulo_SG for invocado para criar o Security Group da EC2, THE Modulo_SG SHALL permitir tráfego de entrada TCP na porta 22 (SSH) e na porta 3000 (API).
2. WHEN o Modulo_SG for invocado para criar o Security Group do RDS, THE Modulo_SG SHALL permitir tráfego de entrada TCP na porta 5432 somente com origem no Security Group da EC2 (não em CIDR aberto).
3. THE Modulo_SG SHALL permitir todo o tráfego de saída (egress) em ambos os Security Groups.
4. THE Modulo_SG SHALL expor o output `sg_id` para consumo por outros módulos.
5. THE Modulo_SG SHALL aplicar tags `Name`, `Project`, `Environment` e `ManagedBy` em todos os Security Groups criados.
6. IF o Security Group do RDS permitir acesso direto pela internet (CIDR `0.0.0.0/0` na porta 5432), THEN THE Modulo_SG SHALL ser considerado não conforme neste requisito.

---

### RF-07: Infraestrutura AWS — Módulo EC2

**User Story:** Como engenheiro de plataforma, quero um módulo Terraform para provisionar a instância EC2 que executará a API na nuvem, para que o servidor seja criado de forma padronizada e reproduzível.

#### Critérios de Aceite

1. WHEN o Modulo_EC2 for invocado, THE Modulo_EC2 SHALL criar uma instância EC2 do tipo `t2.micro` na subnet pública recebida como input.
2. THE Modulo_EC2 SHALL associar o Security Group da EC2 recebido como input à instância.
3. THE Modulo_EC2 SHALL associar o `LabInstanceProfile` à instância EC2 para conceder permissões de serviço sem criar IAM próprio.
4. THE Modulo_EC2 SHALL usar o `user_data` para instalar as dependências da API (Node.js, Git) e iniciar a aplicação na porta 3000.
5. THE Modulo_EC2 SHALL expor os outputs `instance_id`, `public_ip` e `private_ip`.
6. THE Modulo_EC2 SHALL aplicar tags `Name`, `Project`, `Environment` e `ManagedBy` na instância EC2.
7. IF o Modulo_EC2 for configurado para criar IAM Users, Groups ou Roles, THEN THE Modulo_EC2 SHALL ser considerado não conforme neste requisito — apenas `LabInstanceProfile` deve ser usado.

---

### RF-08: Infraestrutura AWS — Módulo RDS

**User Story:** Como engenheiro de plataforma, quero um módulo Terraform para provisionar o banco de dados PostgreSQL gerenciado na AWS, para que a API na nuvem tenha persistência durável e segura.

#### Critérios de Aceite

1. WHEN o Modulo_RDS for invocado, THE Modulo_RDS SHALL criar um DB Subnet Group utilizando as subnets privadas recebidas como input.
2. THE Modulo_RDS SHALL criar uma instância RDS PostgreSQL 15 com `instance_class = "db.t3.micro"` e `allocated_storage = 20`.
3. THE Modulo_RDS SHALL configurar `publicly_accessible = false` para que o banco não seja acessível diretamente pela internet.
4. THE Modulo_RDS SHALL configurar `storage_encrypted = true` para habilitar encriptação em repouso.
5. THE Modulo_RDS SHALL configurar `multi_az = false` para manter o custo dentro do Free Tier do laboratório.
6. THE Modulo_RDS SHALL configurar `skip_final_snapshot = true` para permitir destruição sem snapshot final em ambiente de laboratório.
7. THE Modulo_RDS SHALL associar o Security Group do RDS recebido como input à instância.
8. THE Modulo_RDS SHALL receber `db_name`, `username` e `password` como variáveis de input, sendo `password` marcada como `sensitive = true`.
9. THE Modulo_RDS SHALL expor os outputs `db_endpoint`, `db_name` e `db_port`.
10. THE Modulo_RDS SHALL aplicar tags `Name`, `Project`, `Environment` e `ManagedBy` na instância RDS.
11. IF o Modulo_RDS configurar `publicly_accessible = true`, THEN THE Modulo_RDS SHALL ser considerado não conforme neste requisito.

---

### RF-09: Infraestrutura AWS — Backend Remoto de Estado

**User Story:** Como engenheiro de plataforma, quero o estado do Terraform armazenado remotamente com locking, para que o estado da infraestrutura seja seguro, versionado e compartilhável.

#### Critérios de Aceite

1. THE Backend_Remoto SHALL ser criado com um bucket S3 com versionamento habilitado e encriptação server-side (AES-256) ativada.
2. THE Backend_Remoto SHALL ser criado com Block Public Access ativado em todas as opções (`block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets` = `true`).
3. THE Backend_Remoto SHALL ser criado com uma tabela DynamoDB com partition key `LockID` do tipo String para controle de locking.
4. WHEN o provider S3 backend for configurado no `providers.tf`, THE Terraform SHALL armazenar o arquivo `terraform.tfstate` no bucket S3 com `encrypt = true`.
5. WHEN um `terraform apply` ou `terraform destroy` estiver em execução, THE Backend_Remoto SHALL adquirir um lock na tabela DynamoDB para evitar execuções concorrentes.
6. WHEN o comando `aws s3 ls s3://NOME-DO-BUCKET/` for executado após um `terraform apply`, THE Backend_Remoto SHALL exibir o arquivo `terraform.tfstate` armazenado no bucket.
7. IF o arquivo `terraform.tfstate` for encontrado no repositório Git, THEN THE Repositório SHALL ser considerado não conforme neste requisito.

---

### RF-10: Infraestrutura AWS — Composição dos Módulos e Outputs

**User Story:** Como engenheiro de plataforma, quero que os módulos Terraform se comuniquem entre si via outputs e inputs, para que a infraestrutura seja coesa, sem valores hardcoded e seguindo o padrão de composição ensinado na Aula 06.

#### Critérios de Aceite

1. WHEN o `main.tf` raiz chamar os módulos, THE Terraform SHALL passar `module.vpc.vpc_id` como input `vpc_id` para os módulos Modulo_SG, Modulo_EC2 e Modulo_RDS.
2. WHEN o `main.tf` raiz chamar o Modulo_EC2, THE Terraform SHALL passar `module.vpc.public_subnet_ids[0]` como input `subnet_id`.
3. WHEN o `main.tf` raiz chamar o Modulo_RDS, THE Terraform SHALL passar `module.vpc.private_subnet_ids` como input `subnet_ids`.
4. WHEN o `main.tf` raiz chamar o Modulo_EC2, THE Terraform SHALL passar `module.sg_ec2.sg_id` como input de Security Group.
5. WHEN o `main.tf` raiz chamar o Modulo_RDS, THE Terraform SHALL passar `module.sg_rds.sg_id` como input de Security Group.
6. THE `outputs.tf` raiz SHALL expor ao menos os seguintes valores: IP público da EC2 (`ec2_public_ip`), endpoint do RDS (`rds_endpoint`) e URL completa da API (`api_url`).
7. WHEN `terraform validate` for executado nos diretórios de infraestrutura, THE Terraform SHALL concluir sem erros de validação.
8. WHEN `terraform plan` for executado com credenciais válidas do AWS Academy, THE Terraform SHALL exibir o plano de recursos sem erros.

---

### RF-11: Relatório do Processo com IA como Copiloto

**User Story:** Como avaliador, quero ler um relatório dissertativo descrevendo o processo de uso de IA, para que eu possa verificar que o aluno compreendeu os conceitos das Aulas 01 a 07 e usou a IA com responsabilidade.

#### Critérios de Aceite

1. THE Repositório SHALL conter um arquivo `relatorio.md` na raiz com as 4 questões obrigatórias respondidas de forma dissertativa.
2. THE Relatorio SHALL informar no início qual ferramenta de IA foi utilizada (Kiro, ChatGPT, Claude, Copilot ou outra).
3. WHEN a Questão 1 for avaliada, THE Relatorio SHALL descrever com no mínimo 10 linhas como as Aulas 01 a 07 foram conectadas na construção da solução, detalhando a ordem seguida e o motivo.
4. WHEN a Questão 2 for avaliada, THE Relatorio SHALL descrever com no mínimo 10 linhas os prompts principais usados, o que a IA gerou bem, o que precisou ser corrigido e a comparação com desenvolvimento manual.
5. WHEN a Questão 3 for avaliada, THE Relatorio SHALL descrever com no mínimo 10 linhas a arquitetura AWS provisionada, a razão de o RDS ficar na subnet privada e da EC2 na pública, e os ajustes necessários para o AWS Academy Learner Lab.
6. WHEN a Questão 4 for avaliada, THE Relatorio SHALL descrever com no mínimo 10 linhas o checklist aplicado antes de executar `terraform apply` com código gerado por IA e a reflexão sobre responsabilidade no uso de IA.
7. IF qualquer questão do Relatorio contiver respostas genéricas idênticas ao template sem personalização, THEN THE Relatorio SHALL ser considerado não conforme neste requisito.

---

## Requisitos Não Funcionais

### RNF-01: Segurança — Ausência de Credenciais no Repositório

**User Story:** Como engenheiro de segurança, quero garantir que nenhuma credencial ou chave privada seja versionada, para que a conta AWS e os dados do projeto não sejam comprometidos.

#### Critérios de Aceite

1. THE Repositório SHALL conter um `.gitignore` que exclua `.env`, `*.pem`, `*.tfstate`, `*.tfstate.backup`, `.terraform/` e `terraform.tfvars`.
2. IF qualquer arquivo listado no critério anterior for encontrado no histórico Git do Repositório, THEN THE Repositório SHALL ser considerado não conforme neste requisito.
3. THE `docker-compose.yml` SHALL referenciar variáveis de ambiente via interpolação `${VAR}` e não conter valores de senha ou token hardcoded.
4. THE `variables.tf` do Terraform SHALL marcar as variáveis `db_password` e quaisquer outros segredos com `sensitive = true`.

---

### RNF-02: Organização e Qualidade do Código Terraform

**User Story:** Como engenheiro de plataforma, quero que o código Terraform esteja organizado em arquivos separados por responsabilidade e com tags padronizadas, para que seja legível, auditável e aderente às boas práticas.

#### Critérios de Aceite

1. THE Infraestrutura SHALL organizar o código Terraform em arquivos separados por responsabilidade: `main.tf` (composição), `variables.tf` (variáveis), `outputs.tf` (saídas) e `providers.tf` (provider e backend).
2. THE Infraestrutura SHALL aplicar as tags `Name`, `Project`, `Environment` e `ManagedBy` em todos os recursos AWS provisionados.
3. THE Infraestrutura SHALL declarar `description` em todas as variáveis e outputs dos módulos.
4. THE `providers.tf` SHALL fixar a versão do provider AWS usando o constraint `~> 5.0` e declarar a região `us-east-1`.
5. WHEN `terraform fmt -recursive` for executado, THE Infraestrutura SHALL não apresentar alterações de formatação (código já deve estar formatado).

---

### RNF-03: Compatibilidade com AWS Academy Learner Lab

**User Story:** Como aluno executando no AWS Academy, quero que a infraestrutura seja compatível com as restrições do Learner Lab, para que o `terraform apply` não falhe por limitações do ambiente.

#### Critérios de Aceite

1. THE Infraestrutura SHALL utilizar o `LabInstanceProfile` existente no Learner Lab em vez de criar IAM Instance Profiles próprios.
2. THE Infraestrutura SHALL utilizar a `LabRole` existente no Learner Lab em vez de criar IAM Roles próprias.
3. THE Infraestrutura SHALL provisionar todos os recursos na região `us-east-1`.
4. IF o código Terraform contiver recursos do tipo `aws_iam_user`, `aws_iam_group`, `aws_iam_role` ou `aws_iam_policy`, THEN THE Infraestrutura SHALL ser considerada não conforme neste requisito.
5. THE Infraestrutura SHALL usar instâncias dentro do Free Tier: `t2.micro` para EC2 e `db.t3.micro` para RDS.
6. WHEN as credenciais temporárias do Learner Lab expirarem durante uma sessão, THE Infraestrutura SHALL documentar no `README.md` o procedimento de atualização do `~/.aws/credentials` com novas credenciais via AWS Details.

---

### RNF-04: Reprodutibilidade do Ambiente Local

**User Story:** Como desenvolvedor, quero que qualquer membro da equipe consiga subir o ambiente local com um único comando, para que onboarding e testes locais sejam rápidos e sem surpresas.

#### Critérios de Aceite

1. WHEN `docker compose up -d --build` for executado em uma máquina com Docker e Docker Compose instalados, THE Compose SHALL iniciar todos os serviços sem erros dentro de 120 segundos.
2. WHEN `docker compose ps` for executado após a inicialização, THE Compose SHALL exibir os três serviços (`api`, `postgres`, `redis`) com status `healthy` ou `running`.
3. WHEN `curl http://localhost:3000/health` for executado após o Compose estar ativo, THE API SHALL retornar HTTP 200.
4. WHEN `curl -X POST http://localhost:3000/reservas` for executado com payload JSON válido, THE API SHALL retornar HTTP 201 com a reserva criada, confirmando integração com o Banco_de_Dados.
5. WHEN `docker compose down` for executado e o ambiente for reiniciado com `docker compose up -d`, THE Banco_de_Dados SHALL manter os dados persistidos anteriormente graças ao volume nomeado.

---

### RNF-05: Limpeza de Recursos AWS Após Evidências

**User Story:** Como aluno com créditos limitados no Learner Lab, quero garantir que todos os recursos AWS sejam destruídos após a captura das evidências, para que os créditos não sejam consumidos desnecessariamente.

#### Critérios de Aceite

1. THE Entrega SHALL incluir na pasta `evidencias/` ao menos: `docker-build.txt` (ou screenshot), `compose-ps.txt` (output de `docker compose ps`) e `terraform-plan.txt` (output de `terraform plan`).
2. WHEN as evidências forem capturadas, THE Infraestrutura SHALL ser destruída via `terraform destroy` antes da abertura do Pull Request.
3. IF o bucket S3 do Backend_Remoto contiver versões de objetos, THEN THE Entrega SHALL documentar no `README.md` o comando para esvaziar o bucket incluindo versões antes de executar `terraform destroy` no backend.
4. WHEN o Pull Request for aberto, THE Repositório SHALL não conter evidências de recursos ativos (IPs públicos ativos, endpoints de RDS ainda acessíveis); apenas os outputs capturados são aceitos como evidência.
