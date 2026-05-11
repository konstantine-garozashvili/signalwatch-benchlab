use axum::{
    body::Body,
    http::{Request, StatusCode},
};
use http_body_util::BodyExt;
use serde::de::DeserializeOwned;
use serde_json::{json, Value};
use tower::ServiceExt;

use rest_service::{
    build_app,
    models::{ListSensorsResponse, SensorResponse},
    state::AppState,
};

async fn response_json<T: DeserializeOwned>(response: axum::response::Response) -> T {
    let bytes = response
        .into_body()
        .collect()
        .await
        .expect("body should be readable")
        .to_bytes();
    serde_json::from_slice(&bytes).expect("response body should contain valid json")
}

#[tokio::test]
async fn sensor_crud_flow_works() {
    let app = build_app(AppState::new());

    let create_request = Request::builder()
        .method("POST")
        .uri("/sensors")
        .header("content-type", "application/json")
        .body(Body::from(
            json!({
                "name": "Room temp",
                "sensor_type": "temperature",
                "location": "lab-a",
                "unit": "celsius"
            })
            .to_string(),
        ))
        .expect("create request should be built");

    let create_response = app
        .clone()
        .oneshot(create_request)
        .await
        .expect("create endpoint should respond");
    assert_eq!(create_response.status(), StatusCode::CREATED);
    let created: SensorResponse = response_json(create_response).await;
    assert_eq!(created.sensor.name, "Room temp");
    assert_eq!(created.sensor.status, rest_service::models::SensorStatus::Active);
    let sensor_id = created.sensor.id.clone();

    let list_response = app
        .clone()
        .oneshot(
            Request::builder()
                .method("GET")
                .uri("/sensors")
                .body(Body::empty())
                .expect("list request should be built"),
        )
        .await
        .expect("list endpoint should respond");
    assert_eq!(list_response.status(), StatusCode::OK);
    let list: ListSensorsResponse = response_json(list_response).await;
    assert_eq!(list.sensors.len(), 1);
    assert_eq!(list.sensors[0].id, sensor_id);

    let get_response = app
        .clone()
        .oneshot(
            Request::builder()
                .method("GET")
                .uri(format!("/sensors/{sensor_id}"))
                .body(Body::empty())
                .expect("get request should be built"),
        )
        .await
        .expect("get endpoint should respond");
    assert_eq!(get_response.status(), StatusCode::OK);
    let fetched: SensorResponse = response_json(get_response).await;
    assert_eq!(fetched.sensor.id, sensor_id);

    let update_response = app
        .clone()
        .oneshot(
            Request::builder()
                .method("PUT")
                .uri(format!("/sensors/{sensor_id}"))
                .header("content-type", "application/json")
                .body(Body::from(
                    json!({
                        "name": "Rack pressure",
                        "sensor_type": "pressure",
                        "location": "rack-7",
                        "unit": "psi",
                        "status": "maintenance"
                    })
                    .to_string(),
                ))
                .expect("update request should be built"),
        )
        .await
        .expect("update endpoint should respond");
    assert_eq!(update_response.status(), StatusCode::OK);
    let updated: SensorResponse = response_json(update_response).await;
    assert_eq!(updated.sensor.name, "Rack pressure");
    assert_eq!(updated.sensor.status, rest_service::models::SensorStatus::Maintenance);

    let delete_response = app
        .clone()
        .oneshot(
            Request::builder()
                .method("DELETE")
                .uri(format!("/sensors/{sensor_id}"))
                .body(Body::empty())
                .expect("delete request should be built"),
        )
        .await
        .expect("delete endpoint should respond");
    assert_eq!(delete_response.status(), StatusCode::NO_CONTENT);
}

#[tokio::test]
async fn missing_and_invalid_sensor_ids_return_expected_codes() {
    let app = build_app(AppState::new());

    let invalid_id_response = app
        .clone()
        .oneshot(
            Request::builder()
                .method("GET")
                .uri("/sensors/not-a-uuid")
                .body(Body::empty())
                .expect("invalid id request should be built"),
        )
        .await
        .expect("invalid id endpoint should respond");
    assert_eq!(invalid_id_response.status(), StatusCode::BAD_REQUEST);
    let invalid_body: Value = response_json(invalid_id_response).await;
    assert_eq!(invalid_body["error"], "invalid sensor id");

    let missing_id = "00000000-0000-0000-0000-000000000001";
    let missing_response = app
        .oneshot(
            Request::builder()
                .method("GET")
                .uri(format!("/sensors/{missing_id}"))
                .body(Body::empty())
                .expect("missing id request should be built"),
        )
        .await
        .expect("missing id endpoint should respond");
    assert_eq!(missing_response.status(), StatusCode::NOT_FOUND);
    let missing_body: Value = response_json(missing_response).await;
    assert_eq!(missing_body["error"], "sensor not found");
}
