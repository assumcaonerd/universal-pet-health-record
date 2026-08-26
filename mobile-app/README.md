# Mobile App - Tutor

Aplicativo Flutter do tutor para gerenciar o prontuário de saúde do pet.

## Stack

- Flutter / Dart
- Material 3
- `http` para comunicação com a API
- `flutter_secure_storage` para tokens de sessão
- `intl` para datas

## Já implementado

- login com TOTP ou código de recuperação
- cadastro de tutor
- restauração de sessão local
- logout com revogação do refresh token
- lista de pets do tutor
- cadastro, edição e exclusão de pet com confirmação
- perfil completo do pet
- central de segurança da conta
- solicitação de verificação de e-mail
- carteira de vacinação
- prescrições em modo leitura para o tutor
- alergias ativas e inativas
- cadastro de alergia pelo tutor
- desativação não destrutiva de alergias
- histórico clínico com diagnóstico, tratamento e observações
- visualização do histórico de versões do prontuário quando houver emendas
- carregamento independente de cada seção clínica para reduzir impacto de falhas parciais
- tratamento de erros da API
- tema Material 3
- testes dos modelos `Pet`, `Prescription`, `Allergy` e `MedicalRecord`

## Regras clínicas importantes

O tutor pode consultar prescrições e histórico clínico, mas registros profissionais continuam sujeitos às regras do backend. Criação de prontuário, vacinação e prescrição exige profissional veterinário verificado e autorização clínica válida quando aplicável.

Alergias podem ser informadas pelo próprio tutor. Quando uma alergia deixa de ser vigente, ela é marcada como inativa em vez de ser apagada, preservando o histórico.

Emendas do prontuário não substituem silenciosamente versões anteriores. A interface exibe o número da versão atual e permite consultar versões anteriores quando existentes.

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

1. QR de compartilhamento temporário pelo tutor
2. anexos e exames clínicos no app
3. cache local criptografado
4. sincronização offline-first com resolução visual de conflitos
5. notificações de vacinas, medicamentos e eventos importantes
6. acabamento de acessibilidade, internacionalização e design system
