use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum SensorType {
    Unspecified,
    Temperature,
    Pressure,
    Vibration,
}

impl SensorType {
    pub fn validate_required(&self) -> Result<(), &'static str> {
        match self {
            Self::Unspecified => Err("sensor type is required"),
            _ => Ok(()),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum SensorStatus {
    Unspecified,
    Active,
    Inactive,
    Maintenance,
}

impl SensorStatus {
    pub fn validate_required(&self) -> Result<(), &'static str> {
        match self {
            Self::Unspecified => Err("sensor status is required"),
            _ => Ok(()),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Sensor {
    pub id: String,
    pub name: String,
    pub sensor_type: SensorType,
    pub location: String,
    pub unit: String,
    pub status: SensorStatus,
    pub last_value: f64,
    pub last_reading_at: String,
    pub created_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateSensorRequest {
    pub name: String,
    pub sensor_type: SensorType,
    pub location: String,
    pub unit: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateSensorRequest {
    pub name: String,
    pub sensor_type: SensorType,
    pub location: String,
    pub unit: String,
    pub status: SensorStatus,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SensorResponse {
    pub sensor: Sensor,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ListSensorsResponse {
    pub sensors: Vec<Sensor>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ErrorResponse {
    pub error: String,
}
