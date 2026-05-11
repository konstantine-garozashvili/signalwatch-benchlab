use std::net::SocketAddr;

use grpc_service::{serve, state::AppState};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let addr: SocketAddr = "0.0.0.0:50051".parse()?;
    println!("{}: grpc-service listening on {}", common::service_name(), addr);
    serve(addr, AppState::new()).await
}
