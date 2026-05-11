use axum::{
    extract::{rejection::JsonRejection, Path, State},
    http::StatusCode,
    routing::{get, post},
    Json, Router,
};
use chrono::Utc;
use uuid::Uuid;

use crate::{
    error::ApiError,
    models::{
        CreateSensorRequest, ListSensorsResponse, Sensor, SensorResponse, SensorStatus,
        UpdateSensorRequest,
    },
    state::AppState,
};

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/sensors", post(create_sensor).get(list_sensors))
        .route(
            "/sensors/:id",
            get(get_sensor).put(update_sensor).delete(delete_sensor),
        )
}

async fn create_sensor(
    State(state): State<AppState>,
    request: Result<Json<CreateSensorRequest>, JsonRejection>,
) -> Result<(StatusCode, Json<SensorResponse>), ApiError> {
    let request = request.map_err(|_| ApiError::invalid_request_body())?.0;
    request
        .sensor_type
        .validate_required()
        .map_err(|message| ApiError::BadRequest(message.to_string()))?;

    let id = Uuid::new_v4();
    let now = Utc::now().to_rfc3339();

    let sensor = Sensor {
        id: id.to_string(),
        name: request.name,
        sensor_type: request.sensor_type,
        location: request.location,
        unit: request.unit,
        status: SensorStatus::Active,
        last_value: 0.0,
        last_reading_at: now.clone(),
        created_at: now,
    };

    state.insert_sensor(id, sensor.clone()).await;

    Ok((StatusCode::CREATED, Json(SensorResponse { sensor })))
}

async fn list_sensors(
    State(state): State<AppState>,
) -> Result<(StatusCode, Json<ListSensorsResponse>), ApiError> {
    let sensors = state.list_sensors().await;
    Ok((StatusCode::OK, Json(ListSensorsResponse { sensors })))
}

async fn get_sensor(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<(StatusCode, Json<SensorResponse>), ApiError> {
    let sensor_id = Uuid::parse_str(&id).map_err(|_| ApiError::BadRequest("invalid sensor id".into()))?;
    let sensor = state.get_sensor(&sensor_id).await.ok_or(ApiError::NotFound)?;
    Ok((StatusCode::OK, Json(SensorResponse { sensor })))
}

async fn update_sensor(
    State(state): State<AppState>,
    Path(id): Path<String>,
    request: Result<Json<UpdateSensorRequest>, JsonRejection>,
) -> Result<(StatusCode, Json<SensorResponse>), ApiError> {
    let request = request.map_err(|_| ApiError::invalid_request_body())?.0;
    request
        .sensor_type
        .validate_required()
        .map_err(|message| ApiError::BadRequest(message.to_string()))?;
    request
        .status
        .validate_required()
        .map_err(|message| ApiError::BadRequest(message.to_string()))?;

    let sensor_id = Uuid::parse_str(&id).map_err(|_| ApiError::BadRequest("invalid sensor id".into()))?;
    let mut sensor = state.get_sensor(&sensor_id).await.ok_or(ApiError::NotFound)?;

    sensor.name = request.name;
    sensor.sensor_type = request.sensor_type;
    sensor.location = request.location;
    sensor.unit = request.unit;
    sensor.status = request.status;

    state.insert_sensor(sensor_id, sensor.clone()).await;

    Ok((StatusCode::OK, Json(SensorResponse { sensor })))
}

async fn delete_sensor(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<StatusCode, ApiError> {
    let sensor_id = Uuid::parse_str(&id).map_err(|_| ApiError::BadRequest("invalid sensor id".into()))?;
    let deleted = state.delete_sensor(&sensor_id).await;
    if deleted {
        Ok(StatusCode::NO_CONTENT)
    } else {
        Err(ApiError::NotFound)
    }
}
