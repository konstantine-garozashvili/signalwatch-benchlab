pub mod mapping;
pub mod service;
pub mod state;

pub mod proto {
    tonic::include_proto!("signalwatch.sensor.v1");

    pub const FILE_DESCRIPTOR_SET: &[u8] =
        tonic::include_file_descriptor_set!("sensor_descriptor");
}

use std::net::SocketAddr;

use proto::sensor_service_server::SensorServiceServer;
use service::SensorGrpcService;
use state::AppState;
use tokio_stream::wrappers::TcpListenerStream;
use tonic::transport::Server;
use tonic_reflection::server::Builder as ReflectionBuilder;

pub async fn serve(addr: SocketAddr, state: AppState) -> Result<(), Box<dyn std::error::Error>> {
    let listener = tokio::net::TcpListener::bind(addr).await?;
    let incoming = TcpListenerStream::new(listener);
    let service = SensorGrpcService::new(state);

    let reflection = ReflectionBuilder::configure()
        .register_encoded_file_descriptor_set(proto::FILE_DESCRIPTOR_SET)
        .build_v1()
        .unwrap();

    Server::builder()
        .add_service(reflection)
        .add_service(SensorServiceServer::new(service))
        .serve_with_incoming(incoming)
        .await?;

    Ok(())
}
