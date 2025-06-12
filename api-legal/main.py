from fastapi import FastAPI, Request

app = FastAPI()

@app.get("/")
def index():
    return {"mensaje": "API activa desde VPS"}

@app.post("/preguntar")
async def preguntar(request: Request):
    data = await request.json()
    mensaje = data.get("mensaje", "")
    return {"respuesta": f"Recibí tu pregunta: {mensaje}"}
