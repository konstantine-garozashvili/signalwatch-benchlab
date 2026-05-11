pub mod proto {
    tonic::include_proto!("signalwatch.sensor.v1");
}

fn main() {
    println!("{}: grpc-service started", common::service_name());
}
