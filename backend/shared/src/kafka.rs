use crate::{AppError, AppResult, KafkaConfig};
use rdkafka::config::ClientConfig;
use rdkafka::consumer::{Consumer, StreamConsumer};
use rdkafka::producer::{FutureProducer, FutureRecord};
use rdkafka::Message;
use serde::{Deserialize, Serialize};
use std::time::Duration;
use tracing::{error, info, instrument};

#[derive(Clone)]
pub struct KafkaClient {
    producer: FutureProducer,
    config: KafkaConfig,
}

impl KafkaClient {
    #[instrument(skip(config))]
    pub fn new(config: KafkaConfig) -> AppResult<Self> {
        let mut client_config = ClientConfig::new();
        client_config
            .set("bootstrap.servers", &config.bootstrap_servers)
            .set("message.timeout.ms", "5000");

        if let Some(security_protocol) = &config.security_protocol {
            client_config.set("security.protocol", security_protocol);
        }

        if let Some(sasl_mechanism) = &config.sasl_mechanism {
            client_config.set("sasl.mechanism", sasl_mechanism);
        }

        if let Some(username) = &config.sasl_username {
            client_config.set("sasl.username", username);
        }

        if let Some(password) = &config.sasl_password {
            client_config.set("sasl.password", password);
        }

        let producer: FutureProducer = client_config
            .create()
            .map_err(AppError::Kafka)?;

        Ok(Self { producer, config })
    }

    #[instrument(skip(self, payload))]
    pub async fn publish<T: Serialize>(
        &self,
        topic: &str,
        key: Option<&str>,
        payload: &T,
    ) -> AppResult<()> {
        let payload_json = serde_json::to_string(payload)
            .map_err(AppError::Serialization)?;

        let record = FutureRecord::to(topic)
            .payload(&payload_json);

        let record = if let Some(k) = key {
            record.key(k)
        } else {
            record
        };

        self.producer
            .send(record, Duration::from_secs(5))
            .await
            .map_err(|(e, _)| AppError::Kafka(e))?;

        info!("Message published to topic: {}", topic);
        Ok(())
    }

    #[instrument(skip(self))]
    pub fn create_consumer(&self, group_id: &str) -> AppResult<StreamConsumer> {
        let mut client_config = ClientConfig::new();
        client_config
            .set("bootstrap.servers", &self.config.bootstrap_servers)
            .set("group.id", group_id)
            .set("enable.auto.commit", self.config.enable_auto_commit.to_string())
            .set("session.timeout.ms", self.config.session_timeout_ms.to_string())
            .set("auto.offset.reset", "earliest");

        if let Some(security_protocol) = &self.config.security_protocol {
            client_config.set("security.protocol", security_protocol);
        }

        if let Some(sasl_mechanism) = &self.config.sasl_mechanism {
            client_config.set("sasl.mechanism", sasl_mechanism);
        }

        if let Some(username) = &self.config.sasl_username {
            client_config.set("sasl.username", username);
        }

        if let Some(password) = &self.config.sasl_password {
            client_config.set("sasl.password", password);
        }

        let consumer: StreamConsumer = client_config
            .create()
            .map_err(AppError::Kafka)?;

        Ok(consumer)
    }
}

pub async fn consume_messages<T, F>(
    consumer: &StreamConsumer,
    topics: &[&str],
    mut handler: F,
) -> AppResult<()>
where
    T: for<'a> Deserialize<'a>,
    F: FnMut(T) -> AppResult<()>,
{
    consumer
        .subscribe(topics)
        .map_err(AppError::Kafka)?;

    info!("Started consuming messages from topics: {:?}", topics);

    loop {
        match consumer.recv().await {
            Ok(message) => {
                if let Some(payload) = message.payload() {
                    match serde_json::from_slice::<T>(payload) {
                        Ok(event) => {
                            if let Err(e) = handler(event) {
                                error!("Error handling message: {}", e);
                            }
                        }
                        Err(e) => {
                            error!("Failed to deserialize message: {}", e);
                        }
                    }
                } else {
                    error!("Received empty message");
                }
            }
            Err(e) => {
                error!("Kafka consumer error: {}", e);
                return Err(AppError::Kafka(e));
            }
        }
    }
}
