pub mod api;
pub mod error;
pub mod models;
pub mod state;

use axum::Router;
use state::AppState;

pub fn build_app(state: AppState) -> Router {
    Router::new().merge(api::routes()).with_state(state)
}
