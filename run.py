import json
import sqlite3

def main():
    con = sqlite3.connect("nix-search.db")
    cur = con.cursor()
    cur.execute("CREATE TABLE packages(name, version, description, longDescription)")
    with open("pkgs.json", "r") as pkgs:
        data = json.loads(pkgs.read())
        to_insert = [(name, str(x["version"]) if "version" in x else "", x["description"] if "description" in x else "", x["longDescription"] if "longDescription" in x else "") for (name, x) in data.items()]
        cur.executemany("INSERT INTO packages VALUES(?, ?, ?, ?)", to_insert)
        con.commit()

def query(search):
    connection = sqlite3.connect("nix-search.db")
    cursor = connection.cursor()
    package = f"%{search}%"
    rows = cursor.execute("SELECT * FROM packages WHERE name LIKE ? or description LIKE ? or longDescription LIKE ?", (package, package, package,)).fetchall()
    for row in rows:
        print("Package: {}\nVersion: {}\nDescription: {}\nLong Description:\n{}\n".format(*row))

query("simgrid")
