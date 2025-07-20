import processing.serial.*;

Serial myPort;
boolean portConnected = false;

final int NUM_GRAPHS = 7;
final int GRAPH_LENGTH = 200; // 10초(20Hz)
float[][] data = new float[NUM_GRAPHS][GRAPH_LENGTH];
String[] labels = {
    "Accel X (m/s²)", "Accel Y (m/s²)", "Accel Z (m/s²)",
    "Gyro X (rad/s)", "Gyro Y (rad/s)", "Gyro Z (rad/s)",
    "Temp (°C)"};

// 각 그래프의 데이터 범위를 정의
// MPU6050_RANGE_8_G (가속도계) -> 약 +-78.48 m/s^2
// MPU6050_RANGE_500_DEG (자이로스코프) -> 약 +-8.73 rad/s
// 온도 (일반적인 실내 온도)
float[] minValues = {-80.0f, -80.0f, -80.0f, -10.0f, -10.0f, -10.0f, 0.0f};
float[] maxValues = {80.0f, 80.0f, 80.0f, 10.0f, 10.0f, 10.0f, 50.0f}; // 0~50도 예시

void setup()
{
    // 창의 세로 해상도를 950으로 늘려서 온도 그래프 공간 확보
    size(900, 950);
    try
    {
        myPort = new Serial(this, "COM4", 115200); // 포트명 환경에 맞게 수정
        myPort.bufferUntil('\n');
        portConnected = true;
    }
    catch (Exception e)
    {
        println("Serial Port Connection Error: " + e.getMessage());
        portConnected = false;
    }
}

void draw()
{
    background(255);
    drawConnectionStatus();

    // 그래프 전체 너비에서 좌우 여백을 넉넉하게 둠
    int graphW = (width - 120) / 2;
    // 그래프 4개(가속도 3 + 온도 1)의 행에 맞게 높이 조정. 상단/하단 여백 및 각 그래프 사이 여백 고려
    int graphH = (height - 180) / 4;

    // 왼쪽: 가속도계 (Index 0, 1, 2)
    for (int i = 0; i < 3; i++)
    {
        drawGraph(40, 40 + i * (graphH + 20), graphW, graphH, data[i], labels[i], minValues[i], maxValues[i]);
    }
    // 오른쪽: 자이로스코프 (Index 3, 4, 5)
    for (int i = 0; i < 3; i++)
    {
        drawGraph(80 + graphW, 40 + i * (graphH + 20), graphW, graphH, data[i + 3], labels[i + 3], minValues[i + 3], maxValues[i + 3]);
    }
    // 맨 아래: 온도 (Index 6)
    // 온도 그래프를 4번째 행에 배치하고, 다른 그래프와 동일한 높이(graphH)를 갖도록 조정
    drawGraph(40, 40 + 3 * (graphH + 20), width - 80, graphH, data[6], labels[6], minValues[6], maxValues[6]);
}

// drawGraph 함수에 minVal, maxVal 인자 추가
void drawGraph(int x, int y, int w, int h, float[] values, String label, float minVal, float maxVal)
{
    stroke(0);
    noFill();
    rect(x, y, w, h); // 그래프 경계
    fill(0);
    textSize(14);               // 텍스트 크기
    text(label, x + 5, y + 18); // 라벨 위치

    // y축 값 표시 (Min, Max)
    textSize(12);
    textAlign(RIGHT);
    text(nf(maxVal, 0, 1), x - 5, y + 12);    // Max 값
    text(nf(minVal, 0, 1), x - 5, y + h + 4); // Min 값
    textAlign(LEFT);                          // 다시 기본으로

    // 중앙선 그리기 (0 지점)
    stroke(200); // 회색
    float zeroY = map(0, minVal, maxVal, y + h, y);
    line(x, zeroY, x + w, zeroY);

    stroke(50, 100, 200); // 그래프 색상
    noFill();
    beginShape();
    for (int i = 0; i < values.length; i++)
    {
        // 실제 센서 값 범위 (minVal, maxVal)에 맞춰 매핑
        float val = map(values[i], minVal, maxVal, y + h, y);
        vertex(x + map(i, 0, values.length - 1, 0, w), val);
    }
    endShape();

    // --- 추가된 부분: 실시간 값 표시 ---
    if (values.length > 0)
    {
        String currentValue = nf(values[GRAPH_LENGTH - 1], 0, 2); // 최신 값 가져와서 소수점 2자리까지 표시
        textSize(16);                                             // 값 텍스트 크기
        fill(0);                                                  // 검은색
        textAlign(RIGHT);                                         // 오른쪽 정렬
        text(currentValue, x + w - 5, y + 18);                    // 그래프 오른쪽 상단에 표시 (x + w - 5는 오른쪽 여백)
        textAlign(LEFT);                                          // 다시 기본 정렬로 복원
    }
}

void drawConnectionStatus()
{
    if (portConnected)
    {
        fill(0, 200, 0);           // 초록색
        text("Connected", 30, 20); // 연결 상태 텍스트
    }
    else
    {
        fill(200, 0, 0);              // 빨간색
        text("Disconnected", 30, 20); // 연결 상태 텍스트
    }
    noStroke();
    ellipse(15, 15, 15, 15); // 연결 상태 원
}

void serialEvent(Serial p)
{
    String line = p.readStringUntil('\n');
    if (line == null)
        return;

    line = trim(line);
    String[] tokens = split(line, ',');

    if (tokens.length == NUM_GRAPHS)
    {
        for (int i = 0; i < NUM_GRAPHS; i++)
        {
            try
            {
                arrayCopy(data[i], 1, data[i], 0, GRAPH_LENGTH - 1);
                data[i][GRAPH_LENGTH - 1] = float(tokens[i]);
            }
            catch (NumberFormatException e)
            {
                println("Data format error on token " + i + ": '" + tokens[i] + "' in line: '" + line + "'");
                data[i][GRAPH_LENGTH - 1] = data[i][GRAPH_LENGTH - 2]; // 이전 값 유지
            }
            catch (ArrayIndexOutOfBoundsException e)
            {
                println("Array index out of bounds error. This might happen if GRAPH_LENGTH is too small or data[i] is empty for some reason.");
            }
        }
    }
    else
    {
        println("Received data with incorrect number of tokens: " + tokens.length + " (expected " + NUM_GRAPHS + ") in line: '" + line + "'");
    }
}