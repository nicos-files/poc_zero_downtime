# tools/register_schemas.py
import os, glob, json, requests

SR_URL = os.getenv("SR_URL", "http://schema-registry:8081")

def post_schema(subject, schema_path):
    with open(schema_path, "r", encoding="utf-8") as f:
        # si ya guardás el payload completo { "schema": "..." } lo enviás directo,
        # o construí acá el diccionario: {"schema": json.dumps(avro_schema_dict)}
        payload = json.load(f)
    r = requests.post(f"{SR_URL}/subjects/{subject}/versions",
                      headers={"Content-Type":"application/vnd.schemaregistry.v1+json"},
                      json=payload, timeout=10)
    r.raise_for_status()
    print(subject, "->", r.json())

def main():
    for path in glob.glob("subjects/*-value.avsc"):
        subject = os.path.basename(path).replace(".avsc","")
        post_schema(subject, path)

if __name__ == "__main__":
    main()
