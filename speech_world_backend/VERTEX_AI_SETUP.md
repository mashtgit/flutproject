# Vertex AI Setup Guide

## Обзор

Этот документ описывает настройку аутентификации для Vertex AI API в локальной среде разработки и продакшене.

## Архитектура Аутентификации

```
┌─────────────────────────────────────────────────────────────────┐
│                    Локальная Разработка                          │
│  ┌─────────────────┐         ┌─────────────────────────────┐   │
│  │  Backend (local)│────────►│  Service Account JSON Key   │   │
│  │  GOOGLE_APPLICATION_      │  (vertex.json)              │   │
│  │  CREDENTIALS env var ────►│  • client_email             │   │
│  │                           │  • private_key              │   │
│  └───────────────────────────┴─────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   Vertex AI API │
                    │   (Google Cloud)│
                    └─────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Продакшен (Cloud Run)                         │
│  ┌─────────────────┐         ┌─────────────────────────────┐   │
│  │  Backend (Cloud)│────────►│  Workload Identity          │   │
│  │  (no JSON key)  │         │  • Automatic credentials    │   │
│  │                 │         │  • From metadata server     │   │
│  └───────────────────────────┴─────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Локальная Разработка

### 1. Получение JSON-ключа

1. Перейдите в [Google Cloud Console](https://console.cloud.google.com/)
2. IAM & Admin → Service Accounts
3. Найдите: `vertex-ai-backend-sa@speech-world-003.iam.gserviceaccount.com`
4. Actions → Manage keys → Add key → Create new key → JSON
5. Сохраните файл как `speech_world_backend/vertex.json`

### 2. Настройка окружения

Файл `.env` уже содержит:
```env
GOOGLE_APPLICATION_CREDENTIALS=./vertex.json
```

### 3. Проверка .gitignore

Убедитесь, что JSON-ключ не попадёт в git:
```gitignore
# Service Account Keys (Local Development Only)
speech_world_backend/vertex.json
speech_world_backend/*-sa-*.json
speech_world_backend/*service-account*.json
```

## Продакшен (Cloud Run)

### Workload Identity

В продакшене **JSON-ключ НЕ используется**. Вместо этого:

1. **Service Account** привязан к Cloud Run сервису
2. **Workload Identity** автоматически предоставляет credentials
3. **Vertex AI SDK** получает токен из metadata server

### Настройка Cloud Run

```bash
# Deploy с указанием service account
gcloud run deploy speech-world-backend \
  --image gcr.io/speech-world-003/backend:latest \
  --service-account=vertex-ai-backend-sa@speech-world-003.iam.gserviceaccount.com \
  --region=europe-west1
```

### Важно

- В Cloud Run **не устанавливайте** `GOOGLE_APPLICATION_CREDENTIALS`
- SDK автоматически использует Workload Identity
- Это более безопасно — нет хранения ключей в коде/контейнере

## Проверка Подключения

### Локально

```bash
cd speech_world_backend
npm run dev
```

Лог должен показать успешную инициализацию без ошибок аутентификации.

### В коде (TypeScript)

```typescript
import { VertexAI } from '@google-cloud/aiplatform';

// Автоматически использует GOOGLE_APPLICATION_CREDENTIALS (local)
// или Workload Identity (Cloud Run)
const vertexAI = new VertexAI({
  project: 'speech-world-003',
  location: 'europe-west1',
});
```

## Устранение Неисправностей

### Ошибка: "Could not load the default credentials"

**Причина:** GOOGLE_APPLICATION_CREDENTIALS не установлена или файл не найден

**Решение:**
```bash
# Проверьте путь
ls speech_world_backend/vertex.json

# Установите переменную (временно)
export GOOGLE_APPLICATION_CREDENTIALS=./vertex.json
```

### Ошибка: "Permission denied"

**Причина:** Service Account не имеет роли Vertex AI User

**Решение:**
```bash
# Добавьте роль
gcloud projects add-iam-policy-binding speech-world-003 \
  --member="serviceAccount:vertex-ai-backend-sa@speech-world-003.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"
```

### Ошибка: "Invalid JWT signature"

**Причина:** JSON-ключ повреждён или устарел

**Решение:** Создайте новый ключ в Google Cloud Console

## Безопасность

| Среда | Метод | Безопасность |
|-------|-------|--------------|
| Local | JSON Key | Средняя (ключ на диске) |
| CI/CD | JSON Key (секрет) | Высокая (в зашифрованном виде) |
| Production | Workload Identity | Максимальная (нет ключа) |

### Не делайте:
- ❌ Не коммитьте JSON-ключ в git
- ❌ Не используйте JSON-ключ в продакшене
- ❌ Не передавайте ключ через незащищённые каналы

### Делайте:
- ✅ Регулярно ротируйте ключи
- ✅ Используйте минимально необходимые права
- ✅ Включаёте audit logs для сервисных аккаунтов

## Ссылки

- [Google Cloud Service Accounts](https://cloud.google.com/iam/docs/service-accounts)
- [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [Vertex AI Node.js SDK](https://cloud.google.com/vertex-ai/docs/start/client-libraries#node.js)
