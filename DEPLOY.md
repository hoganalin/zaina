# Deploying ZAINA to GCP

This guide deploys the API container to **Cloud Run** and points the Flutter app at it. The decision rationale is in [ADR-0009](./docs/adr/0009-cloud-run-and-neon.md).

You need:
- A GCP project with billing enabled
- `gcloud` CLI logged in (`gcloud auth login` + `gcloud config set project <PROJECT_ID>`)
- A Neon project + the `DATABASE_URL` from it
- A Firebase project (the same one used for client auth) + a service account key JSON

## 1. Create an Artifact Registry repo

```bash
gcloud artifacts repositories create zaina \
  --repository-format=docker \
  --location=asia-east1 \
  --description="ZAINA container images"

gcloud auth configure-docker asia-east1-docker.pkg.dev
```

## 2. Build and push the API image

From `api/`:

```bash
PROJECT_ID=$(gcloud config get-value project)
TAG=$(git rev-parse --short HEAD)

docker build -t asia-east1-docker.pkg.dev/$PROJECT_ID/zaina/api:$TAG .
docker push asia-east1-docker.pkg.dev/$PROJECT_ID/zaina/api:$TAG
```

## 3. Store secrets in Secret Manager

```bash
# Firebase Admin service account JSON (the one you downloaded for local dev)
gcloud secrets create firebase-service-account --data-file=secrets/zaina-XXXXX-firebase-adminsdk-XXX.json

# Neon database URL
echo -n "postgresql://...your-neon-url..." | \
  gcloud secrets create database-url --data-file=-
```

Grant the Cloud Run runtime service account read access:

```bash
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
RUNTIME_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

for SECRET in firebase-service-account database-url; do
  gcloud secrets add-iam-policy-binding $SECRET \
    --member="serviceAccount:$RUNTIME_SA" \
    --role="roles/secretmanager.secretAccessor"
done
```

## 4. Deploy to Cloud Run

```bash
gcloud run deploy zaina-api \
  --image=asia-east1-docker.pkg.dev/$PROJECT_ID/zaina/api:$TAG \
  --region=asia-east1 \
  --allow-unauthenticated \
  --set-env-vars="NODE_ENV=production,FIREBASE_SERVICE_ACCOUNT_PATH=/secrets/firebase/key.json" \
  --set-secrets="DATABASE_URL=database-url:latest" \
  --set-secrets="/secrets/firebase/key.json=firebase-service-account:latest" \
  --port=3000 \
  --min-instances=0 \
  --max-instances=2
```

## 5. Run migrations against Neon

From a workstation that can reach Neon (anywhere with internet):

```bash
DATABASE_URL="<neon-url>" npx prisma migrate deploy
DATABASE_URL="<neon-url>" npm run prisma:seed
```

## 6. Point the Flutter app at Cloud Run

The mobile app reads `API_BASE_URL` via `--dart-define`:

```bash
cd mobile
flutter build apk --release \
  --dart-define=API_BASE_URL=https://zaina-api-XXXXXXXX.a.run.app
```

For TestFlight / Play Internal you'd configure this in the CI build matrix.

## 7. Verify

```bash
curl https://zaina-api-XXXXXXXX.a.run.app/health
# {"status":"ok","timestamp":"..."}
```

## Notes

- `--allow-unauthenticated` exposes the API publicly. Auth is enforced at the application layer via Firebase token verification — Cloud Run does not gate it.
- Cloud Run scales to zero; first request after idle takes ~1–2s. This is acceptable for portfolio demo. For a production launch use `--min-instances=1` to keep a warm container.
- Apple Sign-In on iOS requires an Apple Developer account ($99/yr) and a configured Service ID in Firebase Console. Google Sign-In is free.
- FCM push delivery requires the Firebase service account permission `Firebase Cloud Messaging API` enabled in the GCP project.
