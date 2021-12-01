provider "google" {
  credentials = file("credentials.json")
  project     = "gcp-adventure-02"
  region      = "us-central1"
  zone        = "us-central1-c"
}