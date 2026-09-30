# Relatório do Processo — Prova do Primeiro Bimestre (DevOps)

**Aluno:** Lucas Rocha
**RA:** `6325123`
**Disciplina:** DevOps
**Semestre:** 2026.2
**Professor:** Alexandre da Costa Tavares Jr
**Ferramentas de IA utilizadas:** Kiro, GitHub Copilot e ChatGPT

## 1. Questão 1 — A Jornada Completa (Aulas 01 a 07)

O projeto teve como objetivo construir a API de Reservas da TechNova e percorrer a jornada apresentada durante o bimestre, começando pelo versionamento e chegando à infraestrutura como código na AWS. Comecei pela organização da aplicação Node.js com Express e PostgreSQL, implementando as rotas de reservas e o health check. A aplicação foi estruturada para utilizar PostgreSQL como persistência, evitando manter os dados somente em memória. A partir disso, trabalhei o versionamento com Git e organizei o projeto em commits utilizando Conventional Commits e uma feature branch chamada `imp/F01`.

A etapa seguinte foi a containerização da aplicação. Foi criado um Dockerfile para a API e uma estrutura de Docker Compose para executar a aplicação junto ao PostgreSQL, utilizando rede própria, volume persistente e healthchecks. Essa etapa representou principalmente os conceitos das Aulas 01 e 02, pois permitiu reproduzir o ambiente local de forma mais controlada.

Depois de validar o ambiente local, passei para Terraform. A infraestrutura foi dividida em módulos para VPC, segurança, computação e RDS, evitando concentrar todos os recursos em um único arquivo. O módulo de VPC criou a rede, subnets, tabelas de rotas e Internet Gateway. O módulo de segurança criou os Security Groups da aplicação e do banco, permitindo acesso ao PostgreSQL somente a partir do Security Group da EC2.

Para o banco de dados foi utilizado Amazon RDS PostgreSQL em subnets privadas, com criptografia de armazenamento e `publicly_accessible = false`. A EC2 foi provisionada em subnet pública para hospedar a API e recebeu o `LabInstanceProfile`, respeitando a limitação do AWS Academy Learner Lab de não criar uma nova estrutura própria de IAM.

Também foi configurado Remote State utilizando S3 para armazenamento do estado e DynamoDB para locking. O backend foi criado e validado antes da utilização pelo Terraform principal. Durante o desenvolvimento, o estado remoto permitiu manter o controle do estado da infraestrutura e também demonstrou o funcionamento do locking.

A Aula 07 apareceu principalmente no uso da IA como copiloto durante o desenvolvimento. Em vez de aceitar automaticamente o código gerado, utilizei a IA para analisar requisitos, propor estrutura, revisar alterações e interpretar erros reais encontrados durante a execução. A ordem geral foi Git e aplicação, Docker e Compose, Terraform, módulos, rede, segurança, RDS, Remote State e finalmente testes na AWS.

A jornada também mostrou que as etapas dependem umas das outras. Um erro aparentemente simples no repositório Git impediu que o bootstrap da EC2 encontrasse o `package.json`, mesmo com a infraestrutura e o RDS provisionados corretamente. Isso reforçou a ideia de que DevOps não consiste apenas em criar recursos, mas em conectar corretamente código, automação, infraestrutura e validação.

## 2. Questão 2 — O Processo com IA como Copiloto

Utilizei principalmente Kiro, GitHub Copilot e ChatGPT como ferramentas de apoio durante o desenvolvimento. O Kiro foi utilizado inicialmente para transformar os requisitos da prova em uma especificação e organizar a implementação. A ideia foi trabalhar primeiro com requisitos, depois arquitetura e então tarefas, evitando começar diretamente escrevendo arquivos Terraform ou Docker sem definir a estrutura do projeto.

Durante a implementação também utilizei o Copilot como agente para analisar o repositório, executar comandos e propor alterações. Uma preocupação constante foi impedir que a ferramenta inventasse resultados. Por isso, os prompts solicitavam explicitamente a execução de comandos reais, apresentação dos diffs completos, execução de `terraform fmt`, `terraform validate` e `terraform plan`, além da interrupção antes de operações destrutivas ou de um `terraform apply` não autorizado.

O ChatGPT foi utilizado principalmente para raciocínio, revisão e diagnóstico. Um exemplo importante ocorreu quando a EC2 não conseguia iniciar a API. Inicialmente foi investigado o bootstrap através do `cloud-init` e posteriormente por comandos do AWS Systems Manager. Foi identificado que `dnf install -y git curl` apresentava conflito com o `curl-minimal` do Amazon Linux 2023. A correção foi reduzida para `dnf install -y git`, e a execução posterior comprovou que Git e Node.js eram instalados corretamente.

Outro problema encontrado mostrou uma limitação importante do uso de IA: uma solução aparentemente correta ainda precisava ser validada no ambiente real. O `user_data` utilizava `git clone` para baixar o repositório e depois executava `npm install` em `/home/ec2-user/app`. Após o código da aplicação ser enviado para a branch `imp/F01`, descobri que o clone do repositório inteiro criava `/home/ec2-user/app/app`, fazendo com que o `package.json` não estivesse no diretório em que o `npm install` era executado.

A IA ajudou bastante a economizar tempo na criação dos módulos, organização dos arquivos e investigação de erros, mas também mostrou que código gerado não pode ser tratado como automaticamente correto. Alguns problemas só apareceram depois de executar a infraestrutura real. O principal ganho foi acelerar a análise e a escrita inicial; o principal risco foi a possibilidade de aceitar uma solução plausível sem verificar seu comportamento.

Por isso, durante o projeto a IA foi utilizada como copiloto e não como autoridade final. As decisões de aplicar Terraform, substituir a EC2 e modificar o bootstrap foram tomadas somente depois da análise dos planos e dos resultados reais. O processo mostrou que o uso responsável de IA depende da capacidade do desenvolvedor de entender o que está sendo gerado e de confrontar a resposta com o comportamento real do sistema.

## 3. Questão 3 — Infraestrutura, Segurança e o Learner Lab

A arquitetura criada na AWS foi baseada em uma VPC própria para a TechNova. Dentro dela foram criadas subnets públicas e privadas, tabelas de rotas, Internet Gateway e Security Groups separados para a aplicação e para o banco de dados. A EC2 foi colocada em uma subnet pública para permitir acesso externo à API na porta 3000. O RDS PostgreSQL foi colocado em subnets privadas e configurado com `publicly_accessible = false`.

A separação entre EC2 e RDS teve como principal objetivo impedir que o banco fosse diretamente acessível pela Internet. O Security Group do RDS permite tráfego PostgreSQL na porta 5432 somente originado pelo Security Group da aplicação. Dessa forma, mesmo estando dentro da mesma VPC, o banco não possui uma regra de acesso público.

O ambiente utilizou duas subnets privadas em zonas de disponibilidade diferentes, permitindo que o DB Subnet Group do RDS tivesse subnets em mais de uma AZ. A subnet pública utilizada pela EC2 ficou em `us-east-1a`. A configuração foi adaptada às características do AWS Academy Learner Lab e aos recursos efetivamente provisionados durante a prova.

O RDS foi criado como PostgreSQL 15, classe `db.t3.micro`, com 20 GB de armazenamento `gp3`, criptografia de armazenamento e acesso público desativado. O banco ficou com status `available` e possuía endpoint próprio. Entretanto, como a aplicação na EC2 não chegou a iniciar devido ao erro de caminho do repositório, não foi possível comprovar por meio do CRUD a comunicação final entre a API e o RDS na nuvem.

Na EC2 foi utilizado o `LabInstanceProfile`, fornecido pelo AWS Academy. Não foram criados usuários, grupos ou roles IAM próprios. Essa foi uma diferença importante em relação a um ambiente AWS convencional, pois o Learner Lab possui permissões controladas e exige o uso dos recursos pré-existentes disponibilizados pelo laboratório.

Outra particularidade foi o uso de credenciais temporárias do Learner Lab, contendo Access Key, Secret Access Key e Session Token. Essas credenciais precisavam ser atualizadas quando o laboratório expirava. Para evitar o versionamento dessas informações, foi utilizado um arquivo local de credenciais ignorado pelo Git.

O Remote State foi configurado em um bucket S3 chamado `technova-terraform-state-20532120`, com versionamento e criptografia, juntamente com uma tabela DynamoDB chamada `technova-terraform-locks` para locking. O backend foi utilizado pelo Terraform durante o provisionamento.

Durante a utilização do laboratório também ocorreu uma limitação relacionada ao AWS Systems Manager. A nova EC2 não chegou a registrar no SSM, impossibilitando o uso de sessões e comandos remotos. Por isso, parte do diagnóstico precisou ser feita utilizando o console output da instância e comandos da AWS CLI. Essa situação reforçou a necessidade de possuir métodos alternativos de observabilidade em ambientes temporários como o Learner Lab.

## 4. Questão 4 — Validação e Responsabilidade

Antes de executar alterações na AWS, utilizei uma sequência de validações para reduzir o risco de aplicar código gerado ou modificado com auxílio de IA sem revisão. O primeiro passo foi analisar o diff das alterações e confirmar que somente os arquivos esperados haviam sido modificados. Em seguida foram utilizados `terraform fmt` e `terraform validate` para verificar formatação e validade da configuração.

O `terraform plan` foi uma das principais etapas de segurança. Antes da substituição da EC2, o plano mostrou explicitamente que somente `module.compute.aws_instance.app` seria substituído, enquanto VPC, RDS, Security Groups, subnets e demais recursos apareciam como `no-op`. Isso permitiu evitar uma aplicação que pudesse destruir ou modificar recursos que não faziam parte da alteração.

Também validei as regras dos Security Groups. A aplicação possuía acesso externo na porta 3000, enquanto o RDS aceitava PostgreSQL somente do Security Group da aplicação. O RDS também estava configurado como não público e com armazenamento criptografado.

Outro cuidado foi verificar o conteúdo que seria enviado ao GitHub. Antes de adicionar a aplicação, foi feita uma varredura procurando senhas, tokens, chaves privadas, arquivos `.env` e outros dados sensíveis. O `node_modules` também foi mantido fora do Git por meio do `.gitignore`. As credenciais temporárias do Learner Lab não foram adicionadas ao repositório.

A validação também ocorreu depois da aplicação da infraestrutura. Um erro no bootstrap revelou que `dnf install -y git curl` entrava em conflito com `curl-minimal`. O erro foi confirmado através dos logs reais da instância, em vez de simplesmente assumir que a IA estava correta. Depois da alteração, uma nova EC2 confirmou através do console output que Git e Node.js eram instalados e que o clone era iniciado.

Entretanto, a validação final revelou outro problema: o repositório possuía a aplicação em `app/`, e o bootstrap clonava o repositório para uma pasta chamada `app`, produzindo a estrutura `/home/ec2-user/app/app`. Como o `npm install` era executado em `/home/ec2-user/app`, o `package.json` não era encontrado e a aplicação não iniciava.

Esse problema demonstra exatamente o motivo pelo qual código gerado por IA precisa ser revisado e testado. Se eu tivesse aceitado o código sem executar o Terraform, analisar o `cloud-init` e testar a aplicação externamente, poderia ter considerado a infraestrutura concluída mesmo com a API indisponível.

O processo Git → Docker → Terraform → Modules também ajudou nessa validação. O conhecimento de cada camada permitiu identificar se um problema estava no código, no container, na rede, no Terraform ou no bootstrap da máquina. Dessa forma, a IA foi utilizada para acelerar o trabalho, mas a responsabilidade pela validação continuou sendo minha.

## 5. Conclusão

A prova permitiu integrar os principais conceitos estudados durante o primeiro bimestre em um único projeto. A aplicação foi estruturada com Node.js, Express e PostgreSQL, recebeu configuração de containerização e ambiente local com Docker Compose, e posteriormente foi utilizada como base para a criação de uma infraestrutura AWS modularizada com Terraform.

A infraestrutura de rede, segurança, computação e banco de dados foi criada por módulos, utilizando composição por inputs e outputs. O RDS PostgreSQL foi provisionado em subnets privadas e a EC2 recebeu o `LabInstanceProfile`, respeitando as restrições do AWS Academy Learner Lab.

O Remote State com S3 e DynamoDB também foi configurado e utilizado. Durante o processo foram encontrados problemas reais envolvendo credenciais temporárias, bootstrap do Amazon Linux, conflito entre `curl` e `curl-minimal`, ausência da aplicação no branch inicialmente utilizado e, posteriormente, o aninhamento do diretório `app`.

A última falha impediu que a API fosse comprovada funcionando na EC2 e que o CRUD fosse validado contra o RDS na nuvem. Portanto, o projeto não será considerado como tendo uma implantação AWS completamente funcional. Ainda assim, o processo de diagnóstico permitiu identificar exatamente a causa do bloqueio final: o caminho utilizado pelo bootstrap para localizar o `package.json`.

O principal aprendizado do projeto foi que uma infraestrutura pode estar corretamente provisionada e ainda assim a aplicação não funcionar. A validação precisa atravessar todas as camadas, desde o código e o Git até o processo de inicialização da máquina e a comunicação com o banco. O uso de IA tornou o desenvolvimento mais rápido, mas as evidências reais mostraram que cada alteração precisa ser entendida, testada e revisada antes de ser considerada concluída.
