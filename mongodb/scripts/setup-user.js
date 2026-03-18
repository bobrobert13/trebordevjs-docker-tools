// Create application user with transaction support
db = db.getSiblingDB('admin');
db.createUser({
  user: "appuser",
  pwd: "apppass",
  roles: [
    { role: "readWrite", db: "myapp" },
    { role: "readWrite", db: "test" }
  ]
});