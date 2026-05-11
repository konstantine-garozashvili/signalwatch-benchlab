pub mod mapping;
pub mod service;
pub mod state;

pub mod proto {
    tonic::include_proto!("signalwatch.sensor.v1");
}

use std::net::SocketAddr;

use proto::sensor_service_server::SensorServiceServer;
use service::SensorGrpcService;
use state::AppState;
use tokio_stream::wrappers::TcpListenerStream;
use tonic::transport::Server;

pub async fn serve(addr: SocketAddr, state: AppState) -> Result<(), Box<dyn std::error::Error>> {
    let listener = tokio::net::TcpListener::bind(addr).await?;
    let incoming = TcpListenerStream::new(listener);
    let service = SensorGrpcService::new(state);

    Server::builder()
        .add_service(SensorServiceServer::new(service))
        .serve_with_incoming(incoming)
        .await?;

    Ok(())
}
