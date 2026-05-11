use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Sensor {
    pub id: String,
    pub name: String,
    pub sensor_type: SensorType,
    pub status: SensorStatus,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum SensorType {
    Temperature,
    Humidity,
    Pressure,
    Motion,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum SensorStatus {
    Active,
    Inactive,
    Faulty,
}

#[cfg(test)]
mod tests {
    use super::{Sensor, SensorStatus, SensorType};

    #[test]
    fn sensor_type_variants_are_comparable() {
        let sensor_type = SensorType::Temperature;

        assert_eq!(sensor_type, SensorType::Temperature);
        assert_ne!(sensor_type, SensorType::Humidity);
    }

    #[test]
    fn sensor_can_be_constructed_with_shared_model() {
        let sensor = Sensor {
            id: "sensor-001".to_string(),
            name: "Primary temperature probe".to_string(),
            sensor_type: SensorType::Temperature,
            status: SensorStatus::Active,
        };

        assert_eq!(sensor.id, "sensor-001");
        assert_eq!(sensor.sensor_type, SensorType::Temperature);
        assert_eq!(sensor.status, SensorStatus::Active);
    }

    #[test]
    fn sensor_json_roundtrip_preserves_values() {
        let sensor = Sensor {
            id: "sensor-002".to_string(),
            name: "Warehouse humidity".to_string(),
            sensor_type: SensorType::Humidity,
            status: SensorStatus::Inactive,
        };

        let json = serde_json::to_string(&sensor).expect("sensor should serialize");
        let deserialized: Sensor =
            serde_json::from_str(&json).expect("sensor should deserialize");

        assert_eq!(deserialized, sensor);
    }
}
