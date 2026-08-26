# Backend - API Central

API do Universal Pet Health Record.

## Stack definida

- Node.js 20
- NestJS + TypeScript
- PostgreSQL
- Prisma ORM
- JWT para autenticação
- Docker

## Funcionalidades implementadas

- `GET /api/health`
- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/pets`
- `GET /api/pets/:id`
- `POST /api/pets`
- `PATCH /api/pets/:id`
- `DELETE /api/pets/:id`
- autorização básica por tutor proprietário
- versionamento incremental do pet
- audit log para criação, edição e exclusão de pets

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

## Segurança

- Senhas são armazenadas apenas como hash bcrypt.
- Rotas de pets exigem Bearer JWT.
- DTOs usam validação estrita e campos não declarados são rejeitados.
- Operações relevantes geram eventos de auditoria.

## Próximas etapas

1. migrations versionadas
2. perfis profissionais e organizações
3. prontuário clínico versionado
4. QR temporário com permissões granulares
5. vacinação e anexos
6. sincronização offline-first
