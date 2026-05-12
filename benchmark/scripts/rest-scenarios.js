import http from "k6/http";
import { check, sleep } from "k6";

const baseUrl = __ENV.REST_BASE_URL || "http://127.0.0.1:8080";
const scenario = (__ENV.BENCH_SCENARIO || "A").toUpperCase();

function buildOptions() {
  if (scenario === "C") {
    return {
      stages: [
        { duration: __ENV.C_STAGE_1_DURATION || "20s", target: Number(__ENV.C_START_CONCURRENCY || "10") },
        { duration: __ENV.C_STAGE_2_DURATION || "20s", target: Number(__ENV.C_MID_CONCURRENCY || "50") },
        { duration: __ENV.C_STAGE_3_DURATION || "20s", target: Number(__ENV.C_END_CONCURRENCY || "100") },
        { duration: __ENV.C_STAGE_4_DURATION || "10s", target: 0 },
      ],
    };
  }

  return {};
}

export const options = buildOptions();

function createPayload() {
  const unique =
    typeof __ITER !== "undefined" && typeof __VU !== "undefined"
      ? `${__VU}-${__ITER}`
      : `setup-${Date.now()}-${Math.floor(Math.random() * 1e9)}`;
  return JSON.stringify({
    name: `bench-${scenario}-${unique}`,
    sensor_type: "temperature",
    location: "atelier-a",
    unit: "C",
  });
}

function createSensor() {
  const response = http.post(`${baseUrl}/sensors`, createPayload(), {
    headers: { "Content-Type": "application/json" },
  });

  check(response, {
    "create sensor status is 201": (r) => r.status === 201,
  });

  return response.json("sensor.id");
}

export function setup() {
  const sensorId = __ENV.SENSOR_ID || createSensor();
  return { sensorId };
}

function runRead(sensorId) {
  const response = http.get(`${baseUrl}/sensors/${sensorId}`);
  check(response, {
    "get sensor status is 200": (r) => r.status === 200,
  });
}

function runWrite() {
  const response = http.post(`${baseUrl}/sensors`, createPayload(), {
    headers: { "Content-Type": "application/json" },
  });
  check(response, {
    "create sensor status is 201": (r) => r.status === 201,
  });
}

export default function (data) {
  if (scenario === "A" || scenario === "C") {
    runRead(data.sensorId);
  } else if (scenario === "B") {
    runWrite();
  } else {
    throw new Error(`Unsupported BENCH_SCENARIO: ${scenario}`);
  }

  sleep(Number(__ENV.THINK_TIME_SECONDS || "0"));
}
