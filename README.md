# Universal Pet Health Record

Sistema unificado de prontuário de saúde animal.

Permite que tutores, veterinários e petshops compartilhem e consultem o histórico de saúde do pet de forma padronizada, segura e offline-first.

## Estrutura do Projeto

```
universal-pet-health-record/
├── .github/workflows/     # CI/CD
├── docs/                  # Documentação e casos de uso
│   ├── api-specs/         # OpenAPI / Swagger
│   └── use-cases/         # Tutor, Veterinário, Petshop
├── schemas/               # Modelos de dados (JSON Schema)
├── backend/               # API Central
├── mobile-app/            # App do Tutor (Offline First)
└── web-portal/            # Painel para Clínicas e Petshops
```

## Componentes

- **schemas/** – Modelos universais de dados (pet-profile, medical-record, vaccination-log)
- **backend/** – API central (Node.js / Go / Python)
- **mobile-app/** – Aplicativo do tutor (Flutter ou React Native), com suporte offline
- **web-portal/** – Painel web para clínicas e petshops (React / Next.js)

## Começando

1. Clone o repositório
2. Explore a documentação em `docs/`
3. Consulte os schemas em `schemas/`
4. Siga as instruções de cada pasta (backend, mobile-app, web-portal) quando disponíveis

## Licença

A definir.
