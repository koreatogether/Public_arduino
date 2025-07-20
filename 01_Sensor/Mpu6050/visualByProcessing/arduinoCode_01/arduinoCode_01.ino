#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>

Adafruit_MPU6050 mpu;

void setup()
{
    Serial.begin(115200);
    while (!Serial)
        delay(10);

    if (!mpu.begin())
    {
        Serial.println("Failed to find MPU6050 chip");
        while (1)
            delay(10);
    }
    mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
    mpu.setGyroRange(MPU6050_RANGE_500_DEG);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
    delay(100);
}

void loop()
{
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);

    Serial.print(a.acceleration.x, 3); // X 가속도 (m/s^2)
    Serial.print(",");
    Serial.print(a.acceleration.y, 3); // Y 가속도 (m/s^2)
    Serial.print(",");
    Serial.print(a.acceleration.z, 3); // Z 가속도 (m/s^2)
    Serial.print(",");
    Serial.print(g.gyro.x, 3); // X 자이로 (rad/s)
    Serial.print(",");
    Serial.print(g.gyro.y, 3); // Y 자이로 (rad/s)
    Serial.print(",");
    Serial.print(g.gyro.z, 3); // Z 자이로 (rad/s)
    Serial.print(",");
    Serial.println(temp.temperature, 2); // 온도 (섭씨)

    delay(50); // 약 20Hz 출력
}