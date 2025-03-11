gcloud builds submit --tag gcr.io/rota-escolar-7c046/stripe-webhook

gcloud run deploy stripe-webhook-service   --image gcr.io/rota-escolar-7c046/stripe-webhook   --platform managed   --region us-central1   --allow-unauthenticated   --set-env-vars "STRIPE_SECRET_KEY=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,STRIPE_WEBHOOK_SECRET=whsec_qmC79u6K6TA7H7MjcZXiXMR3YZsyGzJn"

flutter build apk
