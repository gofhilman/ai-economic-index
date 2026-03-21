variable "project" {
  description = "Project"
  default     = "ai-economic-index"
}

variable "region" {
  description = "Region"
  default     = "asia-southeast2"
}

variable "zone" {
  description = "Zone"
  default     = "asia-southeast2-a"
}

variable "location" {
  description = "Project Location"
  default     = "asia-southeast2"
}

variable "gcs_bucket_name" {
  description = "Storage Bucket Name"
  default     = "ai-economic-index"
}

variable "bq_dataset_name" {
  description = "BigQuery Dataset Name"
  default     = "ai_economic_index"
}
