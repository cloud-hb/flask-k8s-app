from pathlib import Path

from flask import Flask, send_from_directory,redirect, url_for, render_template, request

app = Flask(__name__)


@app.get("/")
def index():
    return {"message": "Flask Kubernetes application is running"}

@app.get("/index")
def index_redirect():
    return redirect(url_for("index"), code=302)

@app.get("/health")
def health():
    return {"status": "ok"}

# @app.get("/favicon.ico")
# def favicon():
#     static_directory = Path(app.root_path) / "static"

#     return send_from_directory(
#         static_directory,
#         "favicon.ico",
#         mimetype="image/vnd.microsoft.icon",
#     )

@app.errorhandler(404)
def handle_not_found(error):
    return {
        "error": "Not Found",
        "path": request.path,
        "message": "The requested endpoint does not exist",
    }, 404

@app.get("/search-page")
def search_page():
    return render_template("search.html")

@app.route("/search", methods=["GET", "POST", "QUERY"])
def search():
    if request.method == "GET":
        return {
            "method": "GET",
            "safe": False,
            "message": "Use POST or QUERY with a JSON request body",
        }

    query_data = request.get_json(silent=True) or {}

    return {
        "method": request.method,
        "safe": request.method == "QUERY",
        "query": query_data,
    }

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)