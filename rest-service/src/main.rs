use std::net::SocketAddr;

use rest_service::{build_app, state::AppState};

#[tokio::main]
async fn main() {
    println!("{}: rest-service started", common::service_name());

    let app = build_app(AppState::new());
    let addr = SocketAddr::from(([0, 0, 0, 0], 8080));
    let listener = tokio::net::TcpListener::bind(addr)
        .await
        .expect("failed to bind address");

    axum::serve(listener, app)
        .await
        .expect("server crashed unexpectedly");
}
