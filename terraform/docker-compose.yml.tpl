version: '3.8'
services:
  service1:
    image: ${ecr_uri}/service1:latest
    ports:
      - "5000:5000"
    environment:
      - FLASK_ENV=production
  service2:
    image: ${ecr_uri}/service2:latest
    ports:
      - "5001:5001"
    environment:
      - FLASK_ENV=production
