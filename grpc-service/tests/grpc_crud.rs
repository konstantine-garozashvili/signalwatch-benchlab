use grpc_service::{
    proto::{
        sensor_service_client::SensorServiceClient, CreateSensorRequest, DeleteSensorRequest,
        GetSensorRequest, ListSensorsRequest, SensorStatus, SensorType, UpdateSensorRequest,
    },
    serve,
    state::AppState,
};
use tonic::Code;

async fn spawn_test_server() -> SensorServiceClient<tonic::transport::Channel> {
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0")
        .await
        .expect("test listener should bind");
    let addr = listener
        .local_addr()
        .expect("test listener should have address");
    drop(listener);

    tokio::spawn(async move {
        serve(addr, AppState::new())
            .await
            .expect("grpc server should run in test");
    });

    let endpoint = format!("http://{}", addr);
    for _ in 0..20 {
        if let Ok(client) = SensorServiceClient::connect(endpoint.clone()).await {
            return client;
        }
        tokio::time::sleep(std::time::Duration::from_millis(25)).await;
    }

    panic!("grpc client should connect");
}

#[tokio::test]
async fn sensor_crud_flow_works() {
    let mut client = spawn_test_server().await;

    let created = client
        .create_sensor(CreateSensorRequest {
            name: "Room temp".into(),
            sensor_type: SensorType::Temperature as i32,
            location: "lab-a".into(),
            unit: "celsius".into(),
        })
        .await
        .expect("create should succeed")
        .into_inner()
        .sensor
        .expect("create should return sensor");
    let sensor_id = created.id.clone();
    assert_eq!(created.status, SensorStatus::Active as i32);

    let list = client
        .list_sensors(ListSensorsRequest {})
        .await
        .expect("list should succeed")
        .into_inner();
    assert_eq!(list.sensors.len(), 1);
    assert_eq!(list.sensors[0].id, sensor_id);

    let fetched = client
        .get_sensor(GetSensorRequest {
            id: sensor_id.clone(),
        })
        .await
        .expect("get should succeed")
        .into_inner()
        .sensor
        .expect("get should return sensor");
    assert_eq!(fetched.id, sensor_id);

    let updated = client
        .update_sensor(UpdateSensorRequest {
            id: sensor_id.clone(),
            name: "Rack pressure".into(),
            sensor_type: SensorType::Pressure as i32,
            location: "rack-7".into(),
            unit: "psi".into(),
            status: SensorStatus::Maintenance as i32,
        })
        .await
        .expect("update should succeed")
        .into_inner()
        .sensor
        .expect("update should return sensor");
    assert_eq!(updated.name, "Rack pressure");
    assert_eq!(updated.status, SensorStatus::Maintenance as i32);

    client
        .delete_sensor(DeleteSensorRequest { id: sensor_id })
        .await
        .expect("delete should succeed");
}

#[tokio::test]
async fn invalid_and_missing_ids_return_expected_codes() {
    let mut client = spawn_test_server().await;

    let invalid_error = client
        .get_sensor(GetSensorRequest {
            id: "not-a-uuid".into(),
        })
        .await
        .expect_err("invalid id should fail");
    assert_eq!(invalid_error.code(), Code::InvalidArgument);

    let missing_error = client
        .get_sensor(GetSensorRequest {
            id: "00000000-0000-0000-0000-000000000001".into(),
        })
        .await
        .expect_err("missing id should fail");
    assert_eq!(missing_error.code(), Code::NotFound);
}

#[tokio::test]
async fn create_and_update_reject_unspecified_enums() {
    let mut client = spawn_test_server().await;

    let create_unspecified_error = client
        .create_sensor(CreateSensorRequest {
            name: "Invalid".into(),
            sensor_type: SensorType::Unspecified as i32,
            location: "lab-a".into(),
            unit: "celsius".into(),
        })
        .await
        .expect_err("unspecified sensor type should fail");
    assert_eq!(create_unspecified_error.code(), Code::InvalidArgument);

    let created = client
        .create_sensor(CreateSensorRequest {
            name: "Room temp".into(),
            sensor_type: SensorType::Temperature as i32,
            location: "lab-a".into(),
            unit: "celsius".into(),
        })
        .await
        .expect("valid create should succeed")
        .into_inner()
        .sensor
        .expect("create should return sensor");

    let update_unspecified_type_error = client
        .update_sensor(UpdateSensorRequest {
            id: created.id.clone(),
            name: "Room temp".into(),
            sensor_type: SensorType::Unspecified as i32,
            location: "lab-a".into(),
            unit: "celsius".into(),
            status: SensorStatus::Active as i32,
        })
        .await
        .expect_err("unspecified sensor type should fail");
    assert_eq!(update_unspecified_type_error.code(), Code::InvalidArgument);

    let update_unspecified_status_error = client
        .update_sensor(UpdateSensorRequest {
            id: created.id,
            name: "Room temp".into(),
            sensor_type: SensorType::Temperature as i32,
            location: "lab-a".into(),
            unit: "celsius".into(),
            status: SensorStatus::Unspecified as i32,
        })
        .await
        .expect_err("unspecified sensor status should fail");
    assert_eq!(
        update_unspecified_status_error.code(),
        Code::InvalidArgument
    );
}

#[tokio::test]
async fn invalid_enum_values_return_invalid_argument() {
    let mut client = spawn_test_server().await;

    let error = client
        .create_sensor(CreateSensorRequest {
            name: "Invalid".into(),
            sensor_type: 99,
            location: "lab-a".into(),
            unit: "celsius".into(),
        })
        .await
        .expect_err("invalid enum should fail");

    assert_eq!(error.code(), Code::InvalidArgument);
}
