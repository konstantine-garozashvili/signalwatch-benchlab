use std::{collections::HashMap, sync::Arc};

use tokio::sync::RwLock;
use uuid::Uuid;

use crate::models::Sensor;

#[derive(Clone, Default)]
pub struct AppState {
    sensors: Arc<RwLock<HashMap<Uuid, Sensor>>>,
}

impl AppState {
    pub fn new() -> Self {
        Self::default()
    }

    pub async fn insert_sensor(&self, id: Uuid, sensor: Sensor) {
        self.sensors.write().await.insert(id, sensor);
    }

    pub async fn list_sensors(&self) -> Vec<Sensor> {
        let mut sensors = self
            .sensors
            .read()
            .await
            .values()
            .cloned()
            .collect::<Vec<_>>();
        sensors.sort_by(|a, b| a.id.cmp(&b.id));
        sensors
    }

    pub async fn get_sensor(&self, id: &Uuid) -> Option<Sensor> {
        self.sensors.read().await.get(id).cloned()
    }

    pub async fn delete_sensor(&self, id: &Uuid) -> bool {
        self.sensors.write().await.remove(id).is_some()
    }
}
