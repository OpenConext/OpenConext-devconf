db = db.getSiblingDB("admin");
// Authenticate as the admin user if necessary
// db.auth('adminUsername', 'adminPassword');
// Create the 'manage' database
db = db.getSiblingDB("manage");
// Create the new user with readWrite role on the 'manage' database
db.createUser({
  user: "managerw",
  pwd: "secret",
  roles: [{ role: "readWrite", db: "manage" }],
});
// create the oidcng database
db = db.getSiblingDB("oidcng");
// Create the new user with readWrite role on the 'oidcng' database
db.createUser({
  user: "oidcngrw",
  pwd: "secret",
  roles: [{ role: "readWrite", db: "oidcng" }],
});

// create the myconext database
db = db.getSiblingDB("myconext");
// Create the new user with readWrite role on the 'myconext' database
db.createUser({
  user: "myconextrw",
  pwd: "secret",
  roles: [{ role: "readWrite", db: "myconext" }],
});
print("Database and user creation script executed successfully.");
