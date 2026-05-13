fn main() -> Result<(), Box<dyn std::error::Error>> {
    tonic_build::configure()
        .build_server(true)
        .build_client(true)
        .file_descriptor_set_path(
            std::path::PathBuf::from(std::env::var("OUT_DIR").unwrap())
                .join("sensor_descriptor.bin"),
        )
        .compile_protos(&["../proto/sensor.proto"], &["../proto"])?;

    println!("cargo:rerun-if-changed=../proto/sensor.proto");
    Ok(())
}
