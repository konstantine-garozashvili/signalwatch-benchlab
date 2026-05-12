//! Prints a new sensor id via CreateSensor (used by benchmark/scripts/run-grpc.sh).

use grpc_service::proto::{
    sensor_service_client::SensorServiceClient, CreateSensorRequest, SensorType,
};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let raw = std::env::var("GRPC_HOST").unwrap_or_else(|_| "127.0.0.1:50051".into());
    let uri = if raw.starts_with("http://") || raw.starts_with("https://") {
        raw
    } else {
        format!("http://{}", raw)
    };

    let mut client = SensorServiceClient::connect(uri).await?;
    let req = CreateSensorRequest {
        name: "grpc-bench-create".into(),
        sensor_type: SensorType::Temperature as i32,
        location: "atelier-a".into(),
        unit: "C".into(),
    };
    let sensor = client
        .create_sensor(req)
        .await?
        .into_inner()
        .sensor
        .ok_or("CreateSensor returned empty sensor")?;

    println!("{}", sensor.id);
    Ok(())
}
