#include <sqlite3.h>
#include <iostream>

#define DB_PATH "nix-search.db"

void print_package(sqlite3_stmt* row) {
  printf("Package: %s\nVersion: %s\nDescription: %s\nLong Description:\n%s\n",
         sqlite3_column_text(row, 0),
         sqlite3_column_text(row, 1),
         sqlite3_column_text(row, 2),
         sqlite3_column_text(row, 3)
         );
}

int main(int argc, char *argv[])
{

  if (argc != 2) {
    fprintf(stderr, "Usage: %s <package>\n", argv[0]);
    return 1;
  }

  sqlite3 *db;
  sqlite3_stmt *res;
  char* package = argv[1];
  std::string delim = "%";
  std::string query = delim + package + delim;

  int rc = sqlite3_open(DB_PATH, &db);
  if (rc != SQLITE_OK) {
    fprintf(stderr, "Cannot open database: %s\n", sqlite3_errmsg(db));
    sqlite3_close(db);
    return 1;
  }

  const char* sql = "SELECT * FROM packages WHERE name LIKE ? or description LIKE ? or longDescription LIKE ?";
  rc = sqlite3_prepare_v2(db, sql, -1, &res, 0);    
  const char* query_c = query.c_str();
  int nb_bytes = sizeof(query_c);
  sqlite3_bind_text(res, 1, query_c, nb_bytes, NULL);
  sqlite3_bind_text(res, 2, query_c, nb_bytes, NULL);
  sqlite3_bind_text(res, 3, query_c, nb_bytes, NULL);

  if (rc != SQLITE_OK) {
    fprintf(stderr, "Failed to fetch data: %s\n", sqlite3_errmsg(db));
    sqlite3_close(db);
    return 1;
  }    
  rc = sqlite3_step(res);
  while (rc == SQLITE_ROW) {
    print_package(res);
    rc = sqlite3_step(res);
  }

  sqlite3_finalize(res);
  sqlite3_close(db);

  return EXIT_SUCCESS;
}
