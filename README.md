CLOUD-RUN-METRICS
=========

*Cloud-run-metrics* is a set of tool to configure monitoring, alerting and SLOs using Terraform. It also include a
basic containerized application used to perform long queries or generate random HTTP errors.

Deploy the app
--------------

To build and deploy the app:
```
docker build -t gcr.io/$PROJECT_ID/instrum-test app
docker push gcr.io/$PROJECT_ID/instrum-test:latest
gcloud run deploy instrum-test --image gcr.io/$PROJECT_ID/instrum-test:latest --region europe-west1
```

To generate load, you can use `siege`:
```
siege -c 250 -r 1000 -H "Authorization: Bearer $(gcloud auth print-identity-token)" "https://$GCR_ENDPOINT/"
```

Configure alerting and SLOs
---------------------------

Run `terraform apply` on the `terraform` folder
