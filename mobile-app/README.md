# Mobile App - Tutor

Aplicativo Flutter do tutor para gerenciar o prontuário de saúde do pet.

## Stack

- Flutter / Dart
- Material 3
- `http` para comunicação com a API
- `flutter_secure_storage` para tokens de sessão
- `intl` para datas

## Já implementado

- login com suporte a MFA
- cadastro de tutor
- restauração de sessão local
- logout com revogação do refresh token
- lista de pets do tutor
- perfil básico do pet
- carteira de vacinação
- tratamento inicial de erros da API
- tema Material 3
- teste do parsing do modelo `Pet`

## API

Por padrão, o Android Emulator usa:

```text
http://10.0.2.2:3000/api
```

Para apontar para outro backend:

```bash
flutter run --dart-define=API_BASE_URL=https://api.exemplo.com/api
```

## Desenvolvimento

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Próximos passos

1. cadastro e edição de pet pela interface
2. verificação de e-mail e painel de segurança
3. prescrições, alergias e histórico clínico
4. QR de compartilhamento temporário
5. cache local e sincronização offline-first
6. notificações de vacinas e eventos importantes
