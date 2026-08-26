# Backend - API Central

Backend inicial do Universal Pet Health Record.

## Stack definida

- Node.js 20
- NestJS + TypeScript
- PostgreSQL
- Prisma ORM
- Docker

## Primeira fundação implementada

- API NestJS executável
- endpoint `GET /api/health`
- Prisma configurado
- modelos iniciais de User, Pet, MedicalRecord, Vaccination, AccessGrant e AuditEvent
- Dockerfile multi-stage
- docker-compose com PostgreSQL
- teste unitário de health check
- CI real com validação Prisma, testes, build e Docker build

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

## Próximas etapas

1. autenticação e autorização
2. CRUD de pets
3. versionamento/auditoria clínica
4. QR temporário com permissões granulares
5. sincronização offline-first
