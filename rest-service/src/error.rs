use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};

use crate::models::ErrorResponse;

#[derive(Debug)]
pub enum ApiError {
    BadRequest(String),
    NotFound,
}

impl ApiError {
    pub fn invalid_request_body() -> Self {
        Self::BadRequest("invalid request body".to_string())
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        match self {
            Self::BadRequest(message) => (
                StatusCode::BAD_REQUEST,
                Json(ErrorResponse { error: message }),
            )
                .into_response(),
            Self::NotFound => (
                StatusCode::NOT_FOUND,
                Json(ErrorResponse {
                    error: "sensor not found".to_string(),
                }),
            )
                .into_response(),
        }
    }
}
