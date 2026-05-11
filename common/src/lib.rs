pub mod models;

pub use models::{Sensor, SensorStatus, SensorType};

pub fn service_name() -> &'static str {
    "signalwatch-common"
}
