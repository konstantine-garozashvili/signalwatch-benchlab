use tonic::Status;
use uuid::Uuid;

use crate::{
    proto,
    state::{
        NewSensor, Sensor, SensorStatus as DomainSensorStatus, SensorType as DomainSensorType,
        UpdateSensorData,
    },
};

pub fn parse_sensor_id(raw: &str) -> Result<Uuid, Status> {
    Uuid::parse_str(raw).map_err(|_| Status::invalid_argument("invalid sensor id"))
}

pub fn to_domain_create(request: proto::CreateSensorRequest) -> Result<NewSensor, Status> {
    Ok(NewSensor {
        name: request.name,
        sensor_type: proto_sensor_type_to_domain(request.sensor_type)?,
        location: request.location,
        unit: request.unit,
    })
}

pub fn to_domain_update(request: proto::UpdateSensorRequest) -> Result<UpdateSensorData, Status> {
    Ok(UpdateSensorData {
        name: request.name,
        sensor_type: proto_sensor_type_to_domain(request.sensor_type)?,
        location: request.location,
        unit: request.unit,
        status: proto_sensor_status_to_domain(request.status)?,
    })
}

pub fn to_proto_sensor(sensor: Sensor) -> proto::Sensor {
    proto::Sensor {
        id: sensor.id.to_string(),
        name: sensor.name,
        sensor_type: domain_sensor_type_to_proto(sensor.sensor_type) as i32,
        location: sensor.location,
        unit: sensor.unit,
        status: domain_sensor_status_to_proto(sensor.status) as i32,
        last_value: sensor.last_value,
        last_reading_at: sensor.last_reading_at,
        created_at: sensor.created_at,
    }
}

fn proto_sensor_type_to_domain(value: i32) -> Result<DomainSensorType, Status> {
    let sensor_type = proto::SensorType::try_from(value)
        .map_err(|_| Status::invalid_argument("invalid sensor type"))?;
    require_sensor_type(sensor_type)
}

fn domain_sensor_type_to_proto(value: DomainSensorType) -> proto::SensorType {
    match value {
        DomainSensorType::Temperature => proto::SensorType::Temperature,
        DomainSensorType::Pressure => proto::SensorType::Pressure,
        DomainSensorType::Vibration => proto::SensorType::Vibration,
    }
}

fn proto_sensor_status_to_domain(value: i32) -> Result<DomainSensorStatus, Status> {
    let status = proto::SensorStatus::try_from(value)
        .map_err(|_| Status::invalid_argument("invalid sensor status"))?;
    require_sensor_status(status)
}

fn domain_sensor_status_to_proto(value: DomainSensorStatus) -> proto::SensorStatus {
    match value {
        DomainSensorStatus::Active => proto::SensorStatus::Active,
        DomainSensorStatus::Inactive => proto::SensorStatus::Inactive,
        DomainSensorStatus::Maintenance => proto::SensorStatus::Maintenance,
    }
}

fn require_sensor_type(sensor_type: proto::SensorType) -> Result<DomainSensorType, Status> {
    match sensor_type {
        proto::SensorType::Unspecified => Err(Status::invalid_argument("sensor type is required")),
        proto::SensorType::Temperature => Ok(DomainSensorType::Temperature),
        proto::SensorType::Pressure => Ok(DomainSensorType::Pressure),
        proto::SensorType::Vibration => Ok(DomainSensorType::Vibration),
    }
}

fn require_sensor_status(status: proto::SensorStatus) -> Result<DomainSensorStatus, Status> {
    match status {
        proto::SensorStatus::Unspecified => Err(Status::invalid_argument("sensor status is required")),
        proto::SensorStatus::Active => Ok(DomainSensorStatus::Active),
        proto::SensorStatus::Inactive => Ok(DomainSensorStatus::Inactive),
        proto::SensorStatus::Maintenance => Ok(DomainSensorStatus::Maintenance),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::state::{Sensor, SensorStatus, SensorType};

    #[test]
    fn create_and_update_mapping_reject_unspecified_enums() {
        let create = to_domain_create(proto::CreateSensorRequest {
            name: "n".into(),
            sensor_type: proto::SensorType::Unspecified as i32,
            location: "l".into(),
            unit: "u".into(),
        });
        assert!(create.is_err());

        let update = to_domain_update(proto::UpdateSensorRequest {
            id: Uuid::new_v4().to_string(),
            name: "n".into(),
            sensor_type: proto::SensorType::Temperature as i32,
            location: "l".into(),
            unit: "u".into(),
            status: proto::SensorStatus::Unspecified as i32,
        });
        assert!(update.is_err());
    }

    #[test]
    fn sensor_roundtrip_mapping_preserves_fields() {
        let id = Uuid::new_v4();
        let sensor = Sensor {
            id,
            name: "Rack pressure".into(),
            sensor_type: SensorType::Pressure,
            location: "rack-7".into(),
            unit: "psi".into(),
            status: SensorStatus::Maintenance,
            last_value: 42.0,
            last_reading_at: "2026-01-01T00:00:00Z".into(),
            created_at: "2026-01-01T00:00:00Z".into(),
        };

        let mapped = to_proto_sensor(sensor);
        assert_eq!(mapped.id, id.to_string());
        assert_eq!(mapped.sensor_type, proto::SensorType::Pressure as i32);
        assert_eq!(mapped.status, proto::SensorStatus::Maintenance as i32);
        assert_eq!(mapped.last_value, 42.0);
    }
}
