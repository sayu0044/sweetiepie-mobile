/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_2236019783")

  // update collection data
  unmarshal({
    "createRule": "@request.auth.id != \"\" && users_id = @request.auth.id",
    "deleteRule": "@request.auth.id != \"\" && users_id = @request.auth.id",
    "listRule": "@request.auth.id != \"\"",
    "updateRule": "@request.auth.id != \"\" && users_id = @request.auth.id",
    "viewRule": "@request.auth.id != \"\" && users_id = @request.auth.id"
  }, collection)

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_2236019783")

  // update collection data
  unmarshal({
    "createRule": "id = @request.auth.id",
    "deleteRule": "id = @request.auth.id",
    "listRule": "id = @request.auth.id",
    "updateRule": "id = @request.auth.id",
    "viewRule": "id = @request.auth.id"
  }, collection)

  return app.save(collection)
})
