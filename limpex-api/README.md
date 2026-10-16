# 🚀 LimpeX API — Backend Services

O **LimpeX API** é o serviço backend responsável por gerenciar a inteligência de negócios, autenticação, persistência de dados e integração fiscal do ecossistema LimpeX. A plataforma conecta clientes a prestadores de serviços de limpeza e serviços gerais, promovendo a formalização de profissionais autônomos via MEI/CNPJ.

---

## 🛠️ Tecnologias Utilizadas

- **Linguagem / Runtime:** Node.js com TypeScript
- **Framework Web:** Express.js
- **Banco de Dados:** PostgreSQL (`pg` driver)
- **Autenticação:** JWT (JSON Web Token) e Bcrypt (criptografia de senhas)
- **Integrações Externas:**
  - **BrasilAPI:** Consulta dinâmica e gratuita de dados cadastrais de CNPJ
  - **ViaCEP:** Preenchimento automático e geolocalização de endereços
- **CORS & Segurança:** Middleware configurado para integração com Flutter (Mobile e Web)

---

## 🗄️ Estrutura do Banco de Dados (PostgreSQL)

O banco de dados do LimpeX é composto pelas seguintes tabelas principais:

1. `perfil`: Definição de papéis no sistema (`CONTRATANTE`, `PRESTADOR`, `ADMINISTRADOR`).
2. `usuario`: Tabela central com credenciais, contatos e status de conta.
3. `usuario_perfil`: Relacionamento muitos-para-muitos entre usuários e papéis.
4. `localizacao` & `endereco`: Gestão de geolocalização, bairros e endereços atendidos.
5. `prestador`: Dados fiscais (CPF/CNPJ), razão social, opção pelo MEI e selo de validação.
6. `trilha_mei_progresso`: Registro de analytics e engajamento da trilha de formalização de prestadores.
7. `categoria_servico` & `servico`: Portfólio de serviços oferecidos por cada prestador.
8. `solicitacao`: Ciclo de vida dos agendamentos e chamados de serviço.
9. `documento_fiscal`: Armazenamento de PDFs/XMLs de notas e recibos gerados.
10. `mensagem` & `avaliacao`: Comunicação via chat e reputação mútua entre usuários.

---

## 🔌 Endpoints da API

### 🔐 Autenticação (`/auth`)
- `POST /auth/register` — Cadastro de novo usuário (`CLIENTE` ou `PRESTADOR`)
- `POST /auth/login` — Autenticação e geração do token JWT

### 📍 Endereços (`/address`)
- `GET /address/viacep/:cep` — Consulta de endereço via CEP (ViaCEP)
- `POST /address` — Vinculação de novo endereço ao usuário autenticado

### 👔 Prestadores & Formalização Fiscal (`/prestador`)
- `GET /prestador/cnpj/:cnpj` — Consulta pública/autenticada de CNPJ via BrasilAPI
- `POST /prestador/dados-fiscais` — Gravação/atualização de dados fiscais (CPF/CNPJ e optante MEI)
- `POST /prestador/trilha-mei` — Registro de progresso na trilha guiada e simulador financeiro MEI

### 🩺 Saúde do Sistema
- `GET /health` — Healthcheck da API e conexão em tempo real com o banco de dados PostgreSQL

---

## 📂 Estrutura de Pastas do Projeto

```text
limpex-api/
├── src/
│   ├── config/          # Conexão com o banco de dados (Pool PostgreSQL)
│   ├── controllers/     # Controladores HTTP das requisições
│   ├── middlewares/     # Middlewares de autenticação JWT e validações
│   ├── repositories/    # Camada de acesso a dados e consultas SQL
│   ├── routes/          # Definição e roteamento dos endpoints Express
│   ├── services/        # Serviços de integração externa (BrasilAPI, ViaCEP)
│   └── server.ts        # Ponto de entrada da aplicação
├── .env.example         # Exemplo de variáveis de ambiente
├── package.json         # Dependências do projeto
└── tsconfig.json        # Configurações do compilador TypeScript
