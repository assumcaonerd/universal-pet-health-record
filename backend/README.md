# Backend - API Central

API do Universal Pet Health Record.

## Stack definida

- Node.js 20
- NestJS + TypeScript
- PostgreSQL
- Prisma ORM
- JWT para autenticação
- Docker
- armazenamento S3 compatível para documentos clínicos

## Funcionalidades implementadas

- autenticação com cadastro/login e Bearer JWT
- CRUD de pets com autorização por tutor proprietário
- versionamento incremental do pet e audit log
- organizações, vínculos profissionais e perfil veterinário verificável
- prontuário clínico versionado e auditável
- autorizações temporárias READ/WRITE com token armazenado apenas como hash
- vacinação e prescrições vinculadas a veterinário e organização
- alergias com desativação não destrutiva
- anexos clínicos com SHA-256, tamanho, MIME type e storage key
- URL pré-assinada de upload S3 por 5 minutos
- verificação de integridade do objeto antes do registro definitivo do anexo
- fila de eventos offline com idempotência por `clientEventId`
- detecção de versão antiga, lacuna de versão e concorrência para eventos offline de Pet

## Fluxo seguro de anexo

1. `POST /api/pets/:petId/attachments/upload-intent` gera uma URL pré-assinada curta.
2. O cliente envia o arquivo diretamente ao storage S3 compatível.
3. `POST /api/pets/:petId/attachments/register` registra os metadados.
4. Antes do registro, o backend verifica tamanho, MIME type e SHA-256 informado no metadata do objeto.

O bucket deve permanecer privado. A API não recebe credenciais de storage do cliente.

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

## Segurança

- senhas armazenadas apenas como hash bcrypt
- rotas privadas protegidas por JWT
- DTOs com validação estrita
- ações clínicas relevantes auditadas
- tokens temporários persistidos apenas como hash SHA-256
- arquivos clínicos limitados a 50 MB nesta fase
- storage key isolada por pet
- conflitos offline antigos não são aceitos como eventos novos

## Próximas etapas

1. aplicar eventos offline aceitos com transação e optimistic locking
2. URLs pré-assinadas de download com autorização e expiração curta
3. política de retenção/quarentena para uploads não finalizados
4. testes de integração PostgreSQL + storage compatível
5. OpenAPI/Swagger e contrato público da API
6. rate limiting, observabilidade e hardening de produção
