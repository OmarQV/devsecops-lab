from pathlib import Path
import sqlite3

from flask import Flask, jsonify, request

app = Flask(__name__)

DATABASE_PATH = Path(__file__).with_name("database.db")


@app.get("/buscar")
def buscar():
    termino = request.args.get("q", "").strip()

    if not termino:
        return jsonify({"error": "Debe proporcionar un término de búsqueda"}), 400

    if len(termino) > 100:
        return jsonify({"error": "El término de búsqueda es demasiado largo"}), 400

    try:
        with sqlite3.connect(DATABASE_PATH) as conexion:
            cursor = conexion.execute(
                "SELECT * FROM productos WHERE nombre = ?",
                (termino,),
            )
            productos = cursor.fetchall()

        return jsonify({"resultados": productos}), 200

    except sqlite3.Error:
        app.logger.exception("Error al consultar la base de datos")
        return jsonify({"error": "No fue posible realizar la consulta"}), 500


@app.get("/evaluar")
def evaluar():
    # Se eliminó eval() y cualquier ejecución dinámica.
    return jsonify(
        {"error": "Operación no permitida por políticas de seguridad"}
    ), 400


@app.get("/health")
def health():
    return jsonify({"status": "ok"}), 200
