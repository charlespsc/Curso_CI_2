# 🚀 Curso de Integração Contínua — GitHub Actions + Docker

Projeto prático de **CI/CD com GitHub Actions**, evoluindo uma API REST desenvolvida em Go para um pipeline capaz de:

- executar testes automatizados;
- compilar a aplicação;
- gerar um artefato de build;
- construir uma imagem Docker;
- autenticar no Docker Hub;
- publicar a imagem com uma tag baseada na referência Git.

Este projeto representa uma evolução do laboratório de Integração Contínua, adicionando a etapa de **containerização e publicação da aplicação**.

---

# 🎯 Objetivo

O objetivo é demonstrar, na prática, a evolução de um pipeline:

```text
Código
  │
  ▼
Testes
  │
  ▼
Build
  │
  ▼
Artefato
  │
  ▼
Imagem Docker
  │
  ▼
Docker Hub
```

A aplicação utilizada continua sendo uma API REST em **Go**, com **Gin, GORM e PostgreSQL**.

---

# 🏗️ Pipeline

```text
                     Git Push / Pull Request
                              │
                              ▼
                    ┌───────────────────┐
                    │   GitHub Actions   │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │       Test        │
                    │ Go + PostgreSQL   │
                    └─────────┬─────────┘
                              │
                         sucesso
                              │
                              ▼
                    ┌───────────────────┐
                    │       Build       │
                    │     go build      │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │ Build Artifact    │
                    │       main        │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │  Docker Workflow  │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │   Docker Build    │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │    Docker Hub     │
                    │  chpsc77/go_ci    │
                    └───────────────────┘
```

---

# 🧰 Tecnologias

| Tecnologia | Utilização |
|---|---|
| **Go** | Aplicação backend |
| **Gin** | Framework HTTP |
| **GORM** | ORM |
| **PostgreSQL** | Banco de dados |
| **Docker** | Containerização |
| **Docker Compose** | Ambiente do PostgreSQL |
| **GitHub Actions** | CI/CD |
| **Docker Hub** | Registry da imagem |
| **Testify** | Testes |

---

# 🔄 CI x CD neste projeto

A parte de **Integração Contínua (CI)** é responsável por verificar o código:

```text
Checkout
   ↓
Setup Go
   ↓
PostgreSQL
   ↓
Testes
   ↓
Build
```

Depois, o pipeline continua para a etapa de empacotamento:

```text
Build
  ↓
Artifact
  ↓
Docker Image
  ↓
Docker Hub
```

Assim, o projeto demonstra a transição de um pipeline de CI para um fluxo de entrega de um artefato containerizado.

> A publicação da imagem no Docker Hub é uma etapa automatizada do workflow. O projeto não implementa, neste estado, um deploy automático da aplicação em um ambiente de produção.

---

# 🧪 Job de testes

O workflow principal está em:

```text
.github/workflows/go.yml
```

O job `test`:

1. faz checkout do código;
2. configura o Go;
3. cria o ambiente Docker do banco;
4. inicia o PostgreSQL;
5. executa os testes.

```yaml
- uses: actions/checkout@v3

- name: Set up Go
  uses: actions/setup-go@v3

- name: Build-DB
  run: docker-compose build

- name: Create-DB
  run: docker-compose up -d

- name: Test
  run: go test -v main_test.go
```

---

# 🧩 Matrix de versões do Go

O pipeline utiliza:

```yaml
matrix:
  go_version: ['1.18', '1.17', '>=1.18']
```

O objetivo é testar a aplicação em diferentes configurações de versão do Go.

O job também utiliza diferentes ambientes Ubuntu:

```yaml
os:
  - ubuntu-latest
  - ubuntu-20.04
```

Isso amplia a cobertura do processo de integração.

---

# 🏗️ Build e artefato

O job `build` depende do job de testes:

```yaml
needs: test
```

Somente depois do sucesso dos testes a aplicação é compilada:

```bash
go build -v main.go
```

O executável `main` é então armazenado como artefato:

```yaml
- name: Upload a Build Artifact
  uses: actions/upload-artifact@v3.1.2
  with:
    name: apiGo
    path: main
```

Fluxo:

```text
Test
 │
 │ sucesso
 ▼
Build
 │
 ▼
main
 │
 ▼
apiGo
```

---

# 🐳 Docker

O projeto possui um `Dockerfile`:

```dockerfile
FROM ubuntu:latest

EXPOSE 8000

WORKDIR /app

ENV HOST=localhost PORT=5432
ENV USER=root PASSWORD=root DBNAME=root

COPY ./main main

CMD [ "./main" ]
```

A imagem utiliza o executável produzido pelo job de build.

O fluxo é:

```text
Go Source
    │
    ▼
go build
    │
    ▼
  main
    │
    ▼
Dockerfile
    │
    ▼
Docker Image
```

---

# 🔗 Workflow reutilizável

O pipeline principal chama um segundo workflow:

```text
.github/workflows/Docker.yml
```

Essa etapa é acionada através de:

```yaml
uses: ./.github/workflows/Docker.yml
secrets: inherit
```

O workflow Docker é responsável por:

1. fazer checkout;
2. configurar Docker Buildx;
3. baixar o artefato `apiGo`;
4. autenticar no Docker Hub;
5. construir a imagem;
6. publicar a imagem.

---

# 📦 Docker Hub

O workflow publica a imagem no repositório:

```text
chpsc77/go_ci
```

A tag é baseada na referência Git:

```yaml
tags: chpsc77/go_ci:${{github.ref_name}}
```

Isso permite associar a imagem publicada à branch ou referência que acionou o pipeline.

---

# 🔐 Secrets

O login no Docker Hub utiliza um Secret do GitHub:

```yaml
password: ${{ secrets.PASSWORD_DOCKER_HUB }}
```

O usuário do Docker Hub está definido no workflow:

```text
chpsc77
```

A senha não fica armazenada diretamente no código.

Para reproduzir o pipeline em outro repositório, o secret precisa ser configurado no GitHub Actions com o nome:

```text
PASSWORD_DOCKER_HUB
```

---

# 🐘 Banco de dados

O PostgreSQL é utilizado durante os testes automatizados.

O `docker-compose.yml` disponibiliza:

```text
PostgreSQL → 5432
pgAdmin    → 54321
```

Configuração do laboratório:

```text
Database: root
User:     root
Password: root
```

A aplicação recebe essas configurações através de variáveis de ambiente:

```text
HOST
PORT
USER
PASSWORD
DBNAME
```

---

# 🔌 API

A aplicação possui endpoints para gerenciamento de alunos:

| Método | Endpoint | Função |
|---|---|---|
| `GET` | `/:nome` | Saudação |
| `GET` | `/alunos` | Lista alunos |
| `GET` | `/alunos/:id` | Busca por ID |
| `GET` | `/alunos/cpf/:cpf` | Busca por CPF |
| `POST` | `/alunos` | Cria aluno |
| `PATCH` | `/alunos/:id` | Edita aluno |
| `DELETE` | `/alunos/:id` | Remove aluno |
| `GET` | `/index` | Interface HTML |

---

# 🧪 Testes

O projeto possui testes utilizando:

- `testing`;
- `httptest`;
- `testify`.

São testados comportamentos como:

- status HTTP;
- saudação;
- listagem;
- consulta por CPF;
- consulta por ID;
- exclusão;
- atualização.

Execução local:

```bash
go test ./...
```

---

# ▶️ Executando localmente

## Pré-requisitos

- Go;
- Docker;
- Docker Compose;
- Git.

## Clonar

```bash
git clone https://github.com/SEU_USUARIO/SEU_REPOSITORIO.git
```

## Entrar

```bash
cd Curso_CI_2-main
```

## Subir PostgreSQL

```bash
docker-compose up -d
```

## Testar

```bash
go test ./...
```

## Compilar

```bash
go build -v main.go
```

## Executar

```bash
./main
```

---

# 📁 Estrutura

```text
Curso_CI_2-main/
│
├── .github/
│   └── workflows/
│       ├── go.yml
│       └── Docker.yml
│
├── assets/
├── controllers/
├── database/
├── models/
├── routes/
├── templates/
│
├── Dockerfile
├── docker-compose.yml
├── go.mod
├── go.sum
├── main.go
├── main_test.go
└── README.md
```

---

# 📚 Conceitos praticados

Este projeto permite praticar:

- Integração Contínua;
- GitHub Actions;
- CI/CD;
- jobs e steps;
- dependência entre jobs;
- reusable workflows;
- artifacts;
- matrix strategy;
- testes automatizados;
- build automatizado;
- Docker;
- Docker Buildx;
- Docker Hub;
- secrets;
- PostgreSQL;
- Go;
- APIs REST;
- Git e GitHub.

---

# 🔬 O que este projeto acrescenta ao laboratório anterior?

A evolução pode ser representada assim:

```text
                 PROJETO CI
                    │
          ┌─────────┴─────────┐
          │                   │
       Testes                Build
          │                   │
          └─────────┬─────────┘
                    │
                    ▼
             Projeto CI + Docker
                    │
                    ▼
              Docker Image
                    │
                    ▼
               Docker Hub
```

O segundo laboratório adiciona ao processo a **entrega automatizada de uma imagem containerizada**.

---

# 🚧 Possíveis melhorias

Algumas evoluções naturais para tornar o pipeline mais próximo de um ambiente profissional:

- [ ] atualizar as versões das GitHub Actions;
- [ ] substituir `ubuntu:latest` por uma versão base controlada;
- [ ] utilizar uma imagem Go multi-stage para reduzir o tamanho final;
- [ ] adicionar cache das dependências Go;
- [ ] adicionar lint (`golangci-lint`);
- [ ] adicionar testes com cobertura;
- [ ] publicar a imagem somente após aprovação;
- [ ] utilizar tags semânticas para versões;
- [ ] adicionar scan de vulnerabilidades da imagem;
- [ ] criar ambiente de staging;
- [ ] implementar deploy automático;
- [ ] adicionar rollback;
- [ ] utilizar OIDC em vez de credenciais estáticas quando aplicável.

---

# ⚠️ Observações

Este projeto é um **laboratório de estudo de CI/CD**.

Ele demonstra os conceitos de automação, testes, build, artefatos e publicação de containers, mas ainda possui elementos que poderiam ser modernizados antes de uma utilização em produção.

Por exemplo:

- algumas GitHub Actions utilizadas são versões antigas;
- o Dockerfile utiliza `ubuntu:latest`;
- as configurações do banco são próprias do ambiente didático;
- não existe deploy automático;
- o pipeline não implementa ainda segurança de supply chain ou scanning de imagens.

Esses pontos fazem parte das possibilidades de evolução do laboratório.

---

## 👨‍💻 Autor

**Charles Pereira**

Tecnologia • Desenvolvimento • DevOps • Infraestrutura • Cloud • CI/CD • Educação Tecnológica

---

⭐ Se este projeto foi útil para você, considere deixar uma estrela no repositório.
