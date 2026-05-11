use std::{collections::HashMap, sync::Arc};

use tokio::sync::RwLock;
use uuid::Uuid;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SensorType {
    Temperature,
    Pressure,
    Vibration,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SensorStatus {
    Active,
    Inactive,
    Maintenance,
}

#[derive(Debug, Clone, PartialEq)]
pub struct Sensor {
    pub id: Uuid,
    pub name: String,
    pub sensor_type: SensorType,
    pub location: String,
    pub unit: String,
    pub status: SensorStatus,
    pub last_value: f64,
    pub last_reading_at: String,
    pub created_at: String,
}

#[derive(Debug, Clone, PartialEq)]
pub struct NewSensor {
    pub name: String,
    pub sensor_type: SensorType,
    pub location: String,
    pub unit: String,
}

#[derive(Debug, Clone, PartialEq)]
pub struct UpdateSensorData {
    pub name: String,
    pub sensor_type: SensorType,
    pub location: String,
    pub unit: String,
    pub status: SensorStatus,
}

#[derive(Clone, Default)]
pub struct AppState {
    sensors: Arc<RwLock<HashMap<Uuid, Sensor>>>,
}

impl AppState {
    pub fn new() -> Self {
        Self::default()
    }

    pub async fn create_sensor(&self, payload: NewSensor) -> Sensor {
        let id = Uuid::new_v4();
        let now = chrono::Utc::now().to_rfc3339();
        let sensor = Sensor {
            id,
            name: payload.name,
            sensor_type: payload.sensor_type,
            location: payload.location,
            unit: payload.unit,
            status: SensorStatus::Active,
            last_value: 0.0,
            last_reading_at: now.clone(),
            created_at: now,
        };

        self.sensors.write().await.insert(id, sensor.clone());
        sensor
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

    pub async fn update_sensor(&self, id: &Uuid, payload: UpdateSensorData) -> Option<Sensor> {
        let mut sensors = self.sensors.write().await;
        let sensor = sensors.get_mut(id)?;

        sensor.name = payload.name;
        sensor.sensor_type = payload.sensor_type;
        sensor.location = payload.location;
        sensor.unit = payload.unit;
        sensor.status = payload.status;

        Some(sensor.clone())
    }

    pub async fn delete_sensor(&self, id: &Uuid) -> bool {
        self.sensors.write().await.remove(id).is_some()
    }
}
