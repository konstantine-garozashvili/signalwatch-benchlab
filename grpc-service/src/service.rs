use tonic::{Request, Response, Status};

use crate::{
    mapping::{parse_sensor_id, to_domain_create, to_domain_update, to_proto_sensor},
    proto::{
        sensor_service_server::SensorService, CreateSensorRequest, CreateSensorResponse,
        DeleteSensorRequest, DeleteSensorResponse, GetSensorRequest, GetSensorResponse,
        ListSensorsRequest, ListSensorsResponse, UpdateSensorRequest, UpdateSensorResponse,
    },
    state::AppState,
};

#[derive(Clone)]
pub struct SensorGrpcService {
    state: AppState,
}

impl SensorGrpcService {
    pub fn new(state: AppState) -> Self {
        Self { state }
    }
}

#[tonic::async_trait]
impl SensorService for SensorGrpcService {
    async fn create_sensor(
        &self,
        request: Request<CreateSensorRequest>,
    ) -> Result<Response<CreateSensorResponse>, Status> {
        let payload = to_domain_create(request.into_inner())?;
        let sensor = self.state.create_sensor(payload).await;

        Ok(Response::new(CreateSensorResponse {
            sensor: Some(to_proto_sensor(sensor)),
        }))
    }

    async fn list_sensors(
        &self,
        _request: Request<ListSensorsRequest>,
    ) -> Result<Response<ListSensorsResponse>, Status> {
        let sensors = self
            .state
            .list_sensors()
            .await
            .into_iter()
            .map(to_proto_sensor)
            .collect();
        Ok(Response::new(ListSensorsResponse { sensors }))
    }

    async fn get_sensor(
        &self,
        request: Request<GetSensorRequest>,
    ) -> Result<Response<GetSensorResponse>, Status> {
        let sensor_id = parse_sensor_id(&request.into_inner().id)?;
        let sensor = self
            .state
            .get_sensor(&sensor_id)
            .await
            .ok_or_else(|| Status::not_found("sensor not found"))?;
        Ok(Response::new(GetSensorResponse {
            sensor: Some(to_proto_sensor(sensor)),
        }))
    }

    async fn update_sensor(
        &self,
        request: Request<UpdateSensorRequest>,
    ) -> Result<Response<UpdateSensorResponse>, Status> {
        let request = request.into_inner();
        let sensor_id = parse_sensor_id(&request.id)?;
        let payload = to_domain_update(request)?;
        let sensor = self
            .state
            .update_sensor(&sensor_id, payload)
            .await
            .ok_or_else(|| Status::not_found("sensor not found"))?;

        Ok(Response::new(UpdateSensorResponse {
            sensor: Some(to_proto_sensor(sensor)),
        }))
    }

    async fn delete_sensor(
        &self,
        request: Request<DeleteSensorRequest>,
    ) -> Result<Response<DeleteSensorResponse>, Status> {
        let sensor_id = parse_sensor_id(&request.into_inner().id)?;
        let deleted = self.state.delete_sensor(&sensor_id).await;
        if !deleted {
            return Err(Status::not_found("sensor not found"));
        }

        Ok(Response::new(DeleteSensorResponse {}))
    }
}
