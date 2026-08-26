# Backend - API Central

API do Universal Pet Health Record.

## Stack definida

- Node.js 20
- NestJS + TypeScript
- PostgreSQL
- Prisma ORM
- JWT + refresh token rotativo
- Docker
- armazenamento S3 compatível para documentos clínicos
- OpenAPI/Swagger

## Funcionalidades implementadas

- cadastro/login com Bearer JWT, refresh token rotativo e logout com revogação
- política forte de senha e recuperação de conta com token de uso único
- verificação de e-mail com token hasheado e expiração
- sessões por dispositivo/contexto com listagem e revogação
- MFA/TOTP opcional, com segredo criptografado em AES-256-GCM
- auditoria de novo contexto de login
- CRUD de pets com autorização por tutor proprietário
- versionamento incremental do pet e audit log
- organizações, vínculos profissionais e perfil veterinário verificável
- prontuário clínico versionado e auditável
- autorizações temporárias READ/WRITE com token armazenado apenas como hash
- vacinação e prescrições vinculadas a veterinário e organização
- alergias com desativação não destrutiva
- anexos clínicos com SHA-256, tamanho, MIME type e storage key
- URLs pré-assinadas de upload e download S3 com expiração curta
- verificação de integridade do objeto antes do registro definitivo do anexo
- fila de eventos offline com idempotência por `clientEventId`
- optimistic locking para aplicação de eventos offline de Pet
- rate limiting global, Helmet, CORS configurável e testes E2E de fronteiras de autenticação

## Fluxo seguro de anexo

1. `POST /api/pets/:petId/attachments/upload-intent` gera uma URL pré-assinada curta.
2. O cliente envia o arquivo diretamente ao storage S3 compatível.
3. `POST /api/pets/:petId/attachments/register` registra os metadados.
4. Antes do registro, o backend verifica tamanho, MIME type e SHA-256 informado no metadata do objeto.
5. O download usa `POST /api/pets/:petId/attachments/:attachmentId/download-intent`, com autorização e URL de curta duração.

O bucket deve permanecer privado. A API não entrega credenciais de storage ao cliente.

## Segurança de conta

Operações sensíveis como compartilhar prontuário, cadastrar perfil profissional, criar organização e transferir anexos exigem e-mail verificado.

O MFA/TOTP é opcional. O fluxo é:

1. `POST /api/account/mfa/setup`
2. adicionar o `otpauthUri` em um autenticador compatível
3. `POST /api/account/mfa/confirm` com um código de 6 dígitos
4. após ativação, `POST /api/auth/login` exige `mfaCode` válido além da senha

Em produção, configure `MFA_ENCRYPTION_KEY` como uma chave aleatória de 32 bytes codificada em Base64. A chave não deve ser versionada no Git.

## Desenvolvimento local

```bash
cp .env.example .env
npm install
npx prisma generate
npm run start:dev
```

Para subir banco + backend:

```bash
docker compose up --build
```

## Configuração S3 compatível

Defina `S3_BUCKET` e `S3_REGION`. Para MinIO, Cloudflare R2 ou outro serviço compatível, use também `S3_ENDPOINT`, `S3_FORCE_PATH_STYLE` e as credenciais adequadas. Em infraestrutura com IAM, as credenciais explícitas podem ser omitidas.

## OpenAPI

Com a API em execução:

- documentação Swagger: `/api/docs`
- documento OpenAPI JSON: `/api/openapi.json`

## Segurança

- senhas armazenadas apenas como hash bcrypt
- refresh tokens, tokens de reset, verificação e compartilhamento persistidos apenas como hash
- segredo TOTP criptografado com AES-256-GCM
- rotas privadas protegidas por JWT
- ações sensíveis condicionadas à verificação de e-mail
- DTOs com validação estrita
- ações clínicas e de segurança relevantes auditadas
- arquivos clínicos limitados a 50 MB nesta fase
- storage key isolada por pet
- conflitos offline antigos não são aplicados sobre versões novas

## Próximas etapas

1. códigos de recuperação MFA e fluxo de recuperação de segundo fator
2. notificação de novo login por e-mail
3. testes de integração com PostgreSQL real e storage S3 compatível
4. política de retenção/quarentena para uploads não finalizados
5. métricas, logs estruturados e observabilidade de produção
6. primeira interface do tutor consumindo o contrato OpenAPI
