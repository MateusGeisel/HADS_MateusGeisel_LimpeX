-- 1. Tabela de Tipos de Perfil de Usuário
CREATE TABLE IF NOT EXISTS perfil (
    id_perfil SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL -- Ex: 'CONTRATANTE', 'PRESTADOR', 'ADMINISTRADOR'
);

-- 2. Tabela de Localização
CREATE TABLE IF NOT EXISTS localizacao (
    id_localizacao SERIAL PRIMARY KEY,
    estado VARCHAR(2) NOT NULL,
    cidade VARCHAR(100) NOT NULL,
    bairro VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8)
);

-- 3. Tabela Central de Usuários
CREATE TABLE IF NOT EXISTS usuario (
    id_usuario SERIAL PRIMARY KEY,
    id_localizacao INT REFERENCES localizacao(id_localizacao),
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    senha VARCHAR(255) NOT NULL,
    telefone VARCHAR(20),
    foto_perfil VARCHAR(255),
    status_conta VARCHAR(20) DEFAULT 'ATIVO', -- ATIVO, SUSPENSO, BLOQUEADO
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tabela Intermediária Usuário - Perfil (Muitos para Muitos)
CREATE TABLE IF NOT EXISTS usuario_perfil (
    id_usuario INT REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    id_perfil INT REFERENCES perfil(id_perfil) ON DELETE CASCADE,
    PRIMARY KEY (id_usuario, id_perfil)
);

-- 5. Tabela de Detalhes Fiscais e Validação do Prestador
CREATE TABLE IF NOT EXISTS prestador (
    id_prestador SERIAL PRIMARY KEY,
    id_usuario INT UNIQUE REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    tipo_documento VARCHAR(10) DEFAULT 'CPF', -- 'CPF' ou 'CNPJ'
    documento_numero VARCHAR(20) UNIQUE NOT NULL,
    razao_social VARCHAR(150),
    inscricao_municipal VARCHAR(50),
    optante_mei BOOLEAN DEFAULT FALSE,
    status_validacao VARCHAR(20) DEFAULT 'PENDENTE', -- PENDENTE, APROVADO, RECUSADO
    selo_formalizado BOOLEAN DEFAULT FALSE,
    id_administrador_validador INT REFERENCES usuario(id_usuario),
    validado_em TIMESTAMP,
    observacao_validacao TEXT
);

-- 6. Tabela Dinâmica de Categorias de Serviços (Gerida pelo Admin)
CREATE TABLE IF NOT EXISTS categoria_servico (
    id_categoria SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL, -- Ex: Assistência Técnica, Beleza, Reformas, Limpeza, Automotivo
    descricao TEXT,
    icone VARCHAR(100),
    ativo BOOLEAN DEFAULT TRUE
);

-- 7. Tabela de Serviços Ofertados pelos Prestadores
CREATE TABLE IF NOT EXISTS servico (
    id_servico SERIAL PRIMARY KEY,
    id_prestador INT REFERENCES prestador(id_prestador) ON DELETE CASCADE,
    id_categoria INT REFERENCES categoria_servico(id_categoria),
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    valor DECIMAL(10, 2),
    modalidade VARCHAR(20) DEFAULT 'DOMICILIO', -- DOMICILIO, ESTABELECIMENTO, REMOTO
    ativo BOOLEAN DEFAULT TRUE,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Tabela de Solicitações / Agendamentos de Serviços
CREATE TABLE IF NOT EXISTS solicitacao (
    id_solicitacao SERIAL PRIMARY KEY,
    id_contratante INT REFERENCES usuario(id_usuario),
    id_prestador INT REFERENCES prestador(id_prestador),
    id_servico INT REFERENCES servico(id_servico),
    status VARCHAR(30) DEFAULT 'PENDENTE', -- PENDENTE, ACEITO, RECUSADO, EM_ANDAMENTO, CONCLUIDO, CANCELADO
    data_agendamento TIMESTAMP NOT NULL,
    observacoes TEXT,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    concluido_em TIMESTAMP
);

-- 9. Tabela de Documentos Fiscais / Recibos Emitidos
CREATE TABLE IF NOT EXISTS documento_fiscal (
    id_documento SERIAL PRIMARY KEY,
    id_solicitacao INT UNIQUE REFERENCES solicitacao(id_solicitacao),
    tipo_documento VARCHAR(20) NOT NULL, -- 'NFSE' ou 'RECIBO'
    numero_nota VARCHAR(50),
    url_pdf VARCHAR(255),
    xml_data TEXT,
    status_emissao VARCHAR(20) DEFAULT 'GERADO', -- PENDENTE, GERADO, ERRO
    emitido_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. Tabela de Chat / Mensagens
CREATE TABLE IF NOT EXISTS mensagem (
    id_mensagem SERIAL PRIMARY KEY,
    id_solicitacao INT REFERENCES solicitacao(id_solicitacao) ON DELETE CASCADE,
    id_remetente INT REFERENCES usuario(id_usuario),
    conteudo TEXT NOT NULL,
    enviada_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 11. Tabela de Avaliação Mútua
CREATE TABLE IF NOT EXISTS avaliacao (
    id_avaliacao SERIAL PRIMARY KEY,
    id_solicitacao INT REFERENCES solicitacao(id_solicitacao),
    id_avaliador INT REFERENCES usuario(id_usuario),
    id_avaliado INT REFERENCES usuario(id_usuario),
    nota INT CHECK (nota >= 1 AND nota <= 5),
    comentario TEXT,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 12. Tabela de Interações no Módulo Trilha MEI (Analytics/Formalização)
CREATE TABLE IF NOT EXISTS trilha_mei_progresso (
    id_progresso SERIAL PRIMARY KEY,
    id_prestador INT REFERENCES prestador(id_prestador) ON DELETE CASCADE,
    etapa_concluida VARCHAR(50) NOT NULL, -- Ex: 'LEITURA_GUIA', 'SIMULACAO_CUSTO', 'REDIRECIONADO_PORTAL'
    data_interacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);