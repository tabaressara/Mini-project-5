import oscP5.*;
import netP5.*;

OscP5 osc;
NetAddress pdAddress;

Table dataset;
int currentRow = 0;

int previousMillis = 0;
int interval = 3000;

float currentTemp = 24.0;  
float currentHumidity = 85.0;
float currentPrecipitation = 0.0;
float currentWindSpeed = 3.0;
String currentWeatherMain = "Rain";

float humidityPulse = 0;

ArrayList<Raindrop> rain = new ArrayList<Raindrop>();

ArrayList<WindParticle> windParticles = new ArrayList<WindParticle>();

PImage iconClear, iconClouds, iconRain, iconSnow, iconThunder, iconFog;

boolean draggingTemp = false; 
boolean draggingPrecipitation = false; 
boolean draggingWindSpeed = false; 
boolean draggingHumidity = false;  

void setup() {
  size(1000, 600);

  dataset = loadTable("Data.csv", "header");
  
  osc = new OscP5(this, 12000);
  pdAddress = new NetAddress("127.0.0.1", 12002); 

  OscMessage msg = new OscMessage("/test");
  msg.add("Hello from Processing!");
  osc.send(msg, pdAddress);

  iconClear   = loadImage("clear.png");
  iconClouds  = loadImage("clouds.png");
  iconRain    = loadImage("rain.png");
  iconSnow    = loadImage("snow.png");
  iconThunder = loadImage("thunderstorm.png");
  iconFog     = loadImage("fog.png");

  if (dataset.getRowCount() > 0) loadRow(0);
}

void draw() {
  background(0);
  
  // Datos de ejemplo: temperatura
  float temperature = random(20, 30);  // Temperatura aleatoria

  // Enviar la temperatura a Pure Data
  OscMessage msg = new OscMessage("/temperature");  // Ruta OSC
  msg.add(temperature);  // Añadir el valor de la temperatura
  osc.send(msg, pdAddress);  // Enviar el mensaje OSC
  
  if (millis() - previousMillis >= interval && currentRow < dataset.getRowCount()) {
    previousMillis = millis();
    loadRow(currentRow);
    sendToPD(currentTemp); 
    currentRow++; 
  }

  displayTemperature(currentTemp);
  displayHumidity(currentHumidity);
  displayWind(currentWindSpeed);
  displayPrecipitation(currentPrecipitation);
  displayWeatherIcon(currentWeatherMain);
}

void loadRow(int rowIndex) {
  currentTemp = dataset.getFloat(rowIndex, "temperature");
  currentHumidity = dataset.getFloat(rowIndex, "humidity");
  currentPrecipitation = dataset.getFloat(rowIndex, "precipitation");
  currentWindSpeed = dataset.getFloat(rowIndex, "wind_speed");
  currentWeatherMain = dataset.getString(rowIndex, "weather_main");
}


void displayTemperature(float temp) {
  float h = map(temp, -10, 40, 0, 400);

  fill(40);
  noStroke();
  rect(80, 100, 60, 420, 20);

  drawVerticalGradient(100, 500 - h, 20, h, color(255, 0, 0), color(0, 0, 255));

  fill(255);
  textSize(18);
  text("Temperature: " + nf(temp, 1, 2) + "°C", 110, 70);
}

void drawVerticalGradient(float x, float y, float w, float h, color c1, color c2) {
  for (int i = 0; i < h; i++) {
    float inter = map(i, 0, h, 0, 1);
    stroke(lerpColor(c1, c2, inter));
    line(x, y + i, x + w, y + i);
  }
}

void displayHumidity(float h) {
  humidityPulse += 0.05;
  float size = map(h, 0, 100, 40, 150);
  float pulse = sin(humidityPulse) * 5;

  float cx = width * 0.3;
  float cy = height * 0.25;

  drawDrop(cx, cy, size + pulse);

  fill(255);
  textAlign(CENTER, CENTER);
  textSize(18);
  text("Humidity: " + nf(h, 1, 1) + "%", cx, cy + 120);
}

void drawDrop(float x, float y, float s) {
  noStroke();
  fill(0, 120, 255);

  beginShape();
  vertex(x, y - s/2);
  bezierVertex(x + s/2, y - s/6, x + s/3, y + s/2, x, y + s/2);
  bezierVertex(x - s/3, y + s/2, x - s/2, y - s/6, x, y - s/2);
  endShape(CLOSE);
}

void displayPrecipitation(float p) {
  float maxWidth = 400;
  float w = map(p, 0, 10, 0, maxWidth); 

  float x = 500; 
  float y = height - 200; 

  fill(40);
  rect(x, y, maxWidth, 20, 10); 

  fill(0, 150, 255);
  rect(x, y, w, 20, 10);

  stroke(255);
  noFill();
  rect(x, y, maxWidth, 20, 10); 

  fill(255);
  textSize(18);
  text("Precipitation: " + nf(p, 1, 2) + " mm", 680, height - 68); 
}

void displayWeatherIcon(String weather) {
  PImage icon = null;

  if      (weather.equals("Clear"))         icon = iconClear;
  else if (weather.equals("Clouds"))        icon = iconClouds;
  else if (weather.equals("Rain"))          icon = iconRain;
  else if (weather.equals("Snow"))          icon = iconSnow;
  else if (weather.equals("Thunderstorm"))  icon = iconThunder;
  else                                      icon = iconFog;

  float cx = width * 0.3;
  float cy = height * 0.7;

  imageMode(CENTER);
  image(icon, cx, cy, 150, 150);

  fill(255);
  textSize(20);
  text("Weather: " + weather, cx, cy + 110);
}

class WindParticle {
  PVector pos, vel;
  float life;

  WindParticle(float x, float y, float speed) {
    pos = new PVector(x, y);
    vel = new PVector(speed * 4, random(-1,1) * speed);
    life = 255;
  }

  void update() {
    pos.add(vel);
    life -= 4;
  }

  void display() {
    noStroke();
    fill(255, life);
    ellipse(pos.x, pos.y, 4, 4);
  }

  boolean isDead() { return life <= 0; }
}

void displayWind(float speed) {
  int amount = int(map(speed, 0, 20, 2, 40));

  float ox = width * 0.55;
  float oy = height * 0.25;

  for (int i = 0; i < amount; i++) {
    windParticles.add(new WindParticle(ox, oy, speed));
  }

  for (int i = windParticles.size() - 1; i >= 0; i--) {
    WindParticle wp = windParticles.get(i);
    wp.update();
    wp.display();
    if (wp.isDead()) windParticles.remove(i);
  }

  fill(255);
  text("Wind Speed: " + nf(speed, 1, 2) + " m/s", ox + 140, oy + 118);
}

void mousePressed() {
  float cx = width * 0.3;
  float cy = height * 0.7;
  if (dist(mouseX, mouseY, cx, cy) < 75) {
    switch (currentWeatherMain) {
      case "Clear":
        currentWeatherMain = "Clouds";
        break;
      case "Clouds":
        currentWeatherMain = "Rain";
        break;
      case "Rain":
        currentWeatherMain = "Thunderstorm";
        break;
      case "Thunderstorm":
        currentWeatherMain = "Snow";
        break;
      case "Snow":
        currentWeatherMain = "Fog";
        break;
      case "Fog":
        currentWeatherMain = "Clear";
        break;
    }
  }

  float cxHumidity = width * 0.3;
  float cyHumidity = height * 0.25;
  float size = map(currentHumidity, 0, 100, 40, 150);  
  if (dist(mouseX, mouseY, cxHumidity, cyHumidity) < size / 2) { 
    draggingHumidity = true;
  }

  if (mouseX > 80 && mouseX < 140 && mouseY > 100 && mouseY < 520) {
    draggingTemp = true; 
  }

  if (mouseX > 500 && mouseX < 900 && mouseY > height - 250 && mouseY < height - 200) {
    draggingWindSpeed = true; 
  }

  if (mouseX > 500 && mouseX < 900 && mouseY > height - 200 && mouseY < height - 180) {
    draggingPrecipitation = true; 
  }
}

void mouseReleased() {
  draggingTemp = false; 
  draggingPrecipitation = false; 
  draggingHumidity = false; 
  draggingWindSpeed = false; 
}

void mouseDragged() {
  if (draggingTemp) {
    currentTemp = map(mouseY, 100, 520, 40, -10); 
    currentTemp = constrain(currentTemp, -10, 40); 
    sendToPD(currentTemp); 
  }

  if (draggingHumidity) {
    float newSize = map(mouseY, 100, 520, 0, 100); 
    currentHumidity = constrain(newSize, 0, 100); 
    sendToPD(currentHumidity); 
  }

  if (draggingPrecipitation) {
    currentPrecipitation = map(mouseX, 500, 900, 0, 10);
    currentPrecipitation = constrain(currentPrecipitation, 0, 10);
    sendToPD(currentPrecipitation);
  }

  if (draggingWindSpeed) {
    currentWindSpeed = map(mouseX, 500, 900, 0.5, 20);
    currentWindSpeed = constrain(currentWindSpeed, 0, 20);
    sendToPD(currentWindSpeed);
  }
}

void sendToPD(float value) {
  OscMessage msg = new OscMessage("/value");
  msg.add(value);
  osc.send(msg, pdAddress);
}

class Raindrop { 
  float x, y, speed; 
  
  Raindrop() { 
    x = random(180, 350); 
    y = random(-200, 0); 
    speed = random(8, 16); 
  } 
  
  void update() { 
    y += speed; 
    if (y > height) y = random(-200, 0); 
  } 

  void display() { 
    stroke(0, 160, 255); 
    strokeWeight(3); 
    line(x, y, x, y + 12);   
  } 
}
