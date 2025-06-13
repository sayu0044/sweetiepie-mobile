/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_4092854851")

  // add field
  collection.fields.addAt(4, new Field({
    "hidden": false,
    "id": "file1083423450",
    "maxSelect": 1,
    "maxSize": 0,
    "mimeTypes": [],
    "name": "gambar",
    "presentable": false,
    "protected": false,
    "required": false,
    "system": false,
    "thumbs": [],
    "type": "file"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_4092854851")

  // remove field
  collection.fields.removeById("file1083423450")

  return app.save(collection)
})
